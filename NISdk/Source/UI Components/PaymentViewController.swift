//
//  PaymentViewController.swift
//  NISdk
//
//  Created by Johnny Peter on 19/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import os.log
import PassKit

typealias MakePaymentCallback = (PaymentRequest) -> Void

typealias MakeSaveCardPaymentCallback = (SavedCardRequest) -> Void

class PaymentViewController: UIViewController {
    private var state: State?
    private weak var shownViewController: UIViewController?

    private let transactionService = TransactionServiceAdapter()
    private weak var cardPaymentDelegate: CardPaymentDelegate?
    private let order: OrderResponse
    private var paymentResponse: PaymentResponse?
    private var paymentToken: String?
    private var accessToken: String?
    private let paymentMedium: PaymentMedium
    private var applePayController: ApplePayController?
    private var applePayDelegate: ApplePayDelegate?
    var applePayRequest: PKPaymentRequest?
    private let cvv: String?
    private var host: String?

    // Apple Pay concurrent-authorization coordination. For Apple Pay we present the
    // native sheet immediately and run the authorization network call in parallel (no
    // intermediate "Authenticating Payment" screen). The access token is only needed
    // once the user authorizes, so this tracks whether that call has resolved and holds
    // a waiter until it does.
    private enum ApplePayAuthState { case pending, success, failed }
    private var applePayAuthState: ApplePayAuthState = .pending
    private var onApplePayAuthResolved: ((Bool) -> Void)?
    // The Apple Pay sheet must be presented only once this controller is actually in the
    // window (viewDidAppear) — presenting from viewDidLoad is dropped by UIKit. Set in
    // viewDidLoad, consumed on first appearance.
    private var pendingApplePaySheetPresentation = false
    // Max time to wait for the background authorization token AFTER the user authorizes
    // the Apple Pay sheet, before failing the sheet rather than hanging on the much
    // longer default URLSession timeout.
    private let applePayAuthTimeout: TimeInterval = 15

    init(order: OrderResponse, cardPaymentDelegate: CardPaymentDelegate,
         applePayDelegate: ApplePayDelegate?, paymentMedium: PaymentMedium) {
        self.order = order
        self.cardPaymentDelegate = cardPaymentDelegate
        self.paymentMedium = paymentMedium
        if let applePayDelegate = applePayDelegate {
            self.applePayDelegate = applePayDelegate
        }
        self.cvv = nil
        super.init(nibName: nil, bundle: nil)
    }

    init(paymentResponse: PaymentResponse, cardPaymentDelegate: CardPaymentDelegate) {
        self.order = OrderResponse()
        self.paymentMedium = .ThreeDSTwo
        self.cardPaymentDelegate = cardPaymentDelegate
        self.paymentResponse = paymentResponse
        self.cvv = nil
        super.init(nibName: nil, bundle: nil)
    }

    init(order: OrderResponse,
         cardPaymentDelegate: CardPaymentDelegate,
         applePayDelegate: ApplePayDelegate?,
         paymentMedium: PaymentMedium,
         cvv: String?
    ) {
        self.order = order
        self.cardPaymentDelegate = cardPaymentDelegate
        self.paymentMedium = paymentMedium
        if let applePayDelegate = applePayDelegate {
            self.applePayDelegate = applePayDelegate
        }
        self.cvv = cvv
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("[NISdk] PaymentViewController loaded — medium: %{public}@, orderRef: %{public}@",
               log: NISdkLogger.payment, type: .info, paymentMedium.rawVal, order.reference ?? "")
        self.performPreAuthChecksAndBeginAuth()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Present the Apple Pay sheet now that we're in the window. Guarded so it only
        // fires on the first appearance, not when the sheet later dismisses back to us.
        if pendingApplePaySheetPresentation {
            pendingApplePaySheetPresentation = false
            initiatePaymentForm()
        }
    }

    // Perform any checks that need to be done before auth
    private func performPreAuthChecksAndBeginAuth() {
        if(self.paymentMedium == .ThreeDSTwo ) {
            guard let authenticationCode = self.paymentResponse?.authenticationCode else {
                self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: .ThreeDSFailed, and: .AuthFailed);
                return
            }

            guard let threeDSTwoAuthenticationURL = self.paymentResponse?.paymentLinks?.paymentLink else {
                self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: .ThreeDSFailed, and: .AuthFailed);
                return
            }

            let authUrl = URL(string: threeDSTwoAuthenticationURL)

            guard let authUrlHost = authUrl?.host,
                    let outletId = paymentResponse?.outletId,
                    let orderReference = paymentResponse?.orderReference else {
                self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: .ThreeDSFailed, and: .AuthFailed);
                return
            }
            self.order.orderLinks = OrderLinks(paymentLink: "",
                                               paymentAuthorizationLink: "",
                                               orderLink: "https://\(authUrlHost)/transactions/outlets/\(outletId)/orders/\(orderReference)",
                                               payPageLink: "")
            self.execThreeDSTwo(using: authenticationCode, domain: authUrlHost)
            return
        }

        if(self.paymentMedium == .ApplePay) {
            NISdkLogger.beginSession("Apple Pay")
            NISdkLogger.event("""
                              applePay — starting. orderRef: \(self.order.reference ?? "nil"), \
                              amount: \(self.order.amount?.getFormattedAmount() ?? "nil"), \
                              applePayLink: \(self.order.embeddedData?.payment?.first?.paymentLinks?.applePayLink ?? "MISSING")
                              """,
                              log: NISdkLogger.payment, type: .info)
            // Apple pay is not enabled by merchant, hence abort payment flow
            if (self.order.embeddedData?.payment?.first?.paymentLinks?.applePayLink) == nil {
                os_log("[NISdk] applePay — aborting: order has no applePayLink. Apple Pay is not enabled on this outlet, or the order was created without it.",
                       log: NISdkLogger.payment, type: .error)
                NISdkLogger.trace("applePay — ABORTING: order has no applePayLink; the sheet will never appear")
                self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: .ThreeDSFailed, and: .AuthFailed);
                return
            }
            // Smoother journey: authorize in the background now, and present the Apple Pay
            // sheet as soon as this controller appears (viewDidAppear) — no blocking
            // "Authenticating Payment" screen. The token is only consumed after the user
            // authorizes (Face/Touch ID), by which time the auth call has almost always
            // completed. The sheet is presented on appear (not here) because presenting
            // from viewDidLoad — before the view is in the window — is silently dropped.
            NISdkLogger.trace("applePay — order OK, starting auth + presenting sheet")
            self.beginConcurrentApplePayAuthorization()
            self.pendingApplePaySheetPresentation = true
            return
        }
        // 1. Perform authorization by aquiring a payment token
        self.authorizePayment()
    }

    private func execThreeDSTwo(using code: String, domain: String) {
        let authUrl = "https://\(domain)/transactions/paymentAuthorization"
        transactionService.authorizePayment(for: code, using: authUrl, on: {
            [weak self] tokens in
            if let paymentToken = tokens["payment-token"], let accessToken = tokens["access-token"] {
                self?.paymentToken = paymentToken
                self?.accessToken = accessToken
                DispatchQueue.main.async { // Use the main thread to update any UI
                    self?.initiatePaymentForm()
                }
            } else {
                self?.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: .AuthFailed)
            }
        })

    }

    private func authorizePayment() {
        os_log("[NISdk] authorizePayment — starting", log: NISdkLogger.auth, type: .info)
        os_log("[NISdk] authorizePayment — authCode: %{public}@, paymentAuthLink: %{public}@, orderLink: %{public}@, payPageLink: %{public}@",
               log: NISdkLogger.auth, type: .debug,
               order.getAuthCode() ?? "nil",
               order.orderLinks?.paymentAuthorizationLink ?? "nil",
               order.orderLinks?.orderLink ?? "nil",
               order.orderLinks?.payPageLink ?? "nil")
        cardPaymentDelegate?.authorizationDidBegin?()
        self.transition(to: .authorizing)
        if let authCode = order.getAuthCode(),
           let paymentLink = order.orderLinks?.paymentAuthorizationLink {
            transactionService.authorizePayment(for: authCode, using: paymentLink, on: {
                [weak self] tokens in
                if let paymentToken = tokens["payment-token"], let accessToken = tokens["access-token"] {
                    // Callback hell...
                    self?.paymentToken = paymentToken
                    self?.accessToken = accessToken
                    os_log("[NISdk] authorizePayment — success, initiating payment form", log: NISdkLogger.auth, type: .info)
                    // 2. Show card payment screen after authorization (payment token is received)
                    DispatchQueue.main.async { // Use the main thread to update any UI
                        self?.cardPaymentDelegate?.authorizationDidComplete?(with: .AuthSuccess)
                        self?.cardPaymentDelegate?.paymentDidBegin?()
                        self?.initiatePaymentForm()
                    }
                } else {
                    os_log("[NISdk] authorizePayment — failed: no tokens in response", log: NISdkLogger.auth, type: .error)
                    self?.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: .AuthFailed)
                }
            })
        } else {
            os_log("[NISdk] authorizePayment — failed: missing authCode or payment link", log: NISdkLogger.auth, type: .error)
            // Close payment view controller if authCode or payment link is broken
            self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: .AuthFailed)
        }
    }

    // Runs the authorization network call for Apple Pay WITHOUT showing the
    // "Authenticating Payment" screen. Tokens are stored on success and any waiter
    // registered via whenApplePayAuthResolved(_:) is notified.
    private func beginConcurrentApplePayAuthorization() {
        os_log("[NISdk] applePay — starting concurrent authorization (no loading screen)", log: NISdkLogger.auth, type: .info)
        cardPaymentDelegate?.authorizationDidBegin?()
        guard let authCode = order.getAuthCode(),
              let paymentLink = order.orderLinks?.paymentAuthorizationLink else {
            os_log("[NISdk] applePay — authorization failed: missing authCode or payment link", log: NISdkLogger.auth, type: .error)
            self.resolveApplePayAuth(success: false)
            return
        }
        transactionService.authorizePayment(for: authCode, using: paymentLink, on: {
            [weak self] tokens in
            guard let self = self else { return }
            if let paymentToken = tokens["payment-token"], let accessToken = tokens["access-token"] {
                self.paymentToken = paymentToken
                self.accessToken = accessToken
                os_log("[NISdk] applePay — concurrent authorization succeeded", log: NISdkLogger.auth, type: .info)
                NISdkLogger.trace("applePay — authorization succeeded (access token received)")
                DispatchQueue.main.async {
                    self.cardPaymentDelegate?.authorizationDidComplete?(with: .AuthSuccess)
                    self.cardPaymentDelegate?.paymentDidBegin?()
                    self.resolveApplePayAuth(success: true)
                }
            } else {
                os_log("[NISdk] applePay — concurrent authorization failed: no tokens", log: NISdkLogger.auth, type: .error)
                NISdkLogger.trace("applePay — authorization FAILED: no tokens in response")
                DispatchQueue.main.async {
                    self.resolveApplePayAuth(success: false)
                }
            }
        })
    }

    private func resolveApplePayAuth(success: Bool) {
        applePayAuthState = success ? .success : .failed
        let waiter = onApplePayAuthResolved
        onApplePayAuthResolved = nil
        waiter?(success)
    }

    // Invokes `completion` once authorization has resolved: immediately if it already
    // has, otherwise when it does — or `false` if it hasn't within `applePayAuthTimeout`.
    // `true` means the access token is available. The completion is guaranteed to run
    // exactly once (resolution or timeout, whichever comes first).
    private func whenApplePayAuthResolved(_ completion: @escaping (Bool) -> Void) {
        var hasFired = false
        let fireOnce: (Bool) -> Void = { success in
            if hasFired { return }
            hasFired = true
            completion(success)
        }
        switch applePayAuthState {
        case .success:
            fireOnce(true)
        case .failed:
            fireOnce(false)
        case .pending:
            onApplePayAuthResolved = fireOnce
            let timeout = applePayAuthTimeout
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard !hasFired else { return }
                os_log("[NISdk] applePay — token not received within %.0fs of authorization, failing sheet", log: NISdkLogger.auth, type: .error, timeout)
                self?.onApplePayAuthResolved = nil
                fireOnce(false)
            }
        }
    }

    private func initiatePaymentForm() {
        os_log("[NISdk] initiatePaymentForm — medium: %{public}@", log: NISdkLogger.payment, type: .info, paymentMedium.rawVal)
        switch paymentMedium {
        case .Card:
            let cardPaymentViewController = CardPaymentViewController(makePaymentCallback: self.makePayment, order: order, onCancel: {
                [weak self] in
                if NISdk.sharedInstance.shouldShowCancelAlert {
                    self?.showCancelPaymentAlert(with: .PaymentCancelled, and: nil, and: nil)
                } else {
                    self?.finishPaymentAndClosePaymentViewController(with: .PaymentCancelled, and: nil, and: nil)
                }
            })
            self.transition(to: .renderCardPaymentForm(cardPaymentViewController))
            break
        case .ApplePay:
            if let applePayRequest = applePayRequest {
                applePayController = ApplePayController(applePayDelegate: self.applePayDelegate!,
                                                        order: order,
                                                        onDismissCallback: handlePaymentResponse,
                                                        onAuthorizeApplePayCallback: handleApplePayAuthorization)
                if let allowedPKPaymentNetworks = order.paymentMethods?.card?.map({ $0.pkNetworkType }) {
                    applePayRequest.supportedNetworks = Array(Set(allowedPKPaymentNetworks))
                }
                // Dont use container view controllers for apple pay
                let pkPaymentAuthorizationVC = PKPaymentAuthorizationViewController(paymentRequest: applePayRequest)
                if let pkPaymentAuthorizationVC = pkPaymentAuthorizationVC {
                    NISdkLogger.event("""
                                      applePay — presenting the Apple Pay sheet. \
                                      merchantIdentifier: \(applePayRequest.merchantIdentifier), \
                                      countryCode: \(applePayRequest.countryCode), \
                                      currencyCode: \(applePayRequest.currencyCode), \
                                      supportedNetworks: \(applePayRequest.supportedNetworks.map({ $0.rawValue }).joined(separator: ","))
                                      """,
                                      log: NISdkLogger.payment, type: .info)
                    pkPaymentAuthorizationVC.delegate = applePayController
                    self.shownViewController?.remove()
                    self.present(pkPaymentAuthorizationVC, animated: false, completion: nil)
                    return
                }
                // PKPaymentAuthorizationViewController returns nil rather than throwing when
                // the request is unusable, and the sheet then never appears. The usual causes
                // are a merchant identifier the app isn't entitled to, a missing Apple Pay
                // (In-App Payments) entitlement, an empty supportedNetworks list, or an
                // invalid country/currency code. Log everything needed to tell them apart.
                os_log("""
                       [NISdk] applePay — PKPaymentAuthorizationViewController(paymentRequest:) returned nil, \
                       so the Apple Pay sheet cannot be shown. merchantIdentifier: %{public}@, countryCode: %{public}@, \
                       currencyCode: %{public}@, supportedNetworks: %{public}@, summaryItems: %{public}d, \
                       canMakePayments: %{public}@, canMakePaymentsUsingNetworks: %{public}@
                       """,
                       log: NISdkLogger.payment, type: .error,
                       applePayRequest.merchantIdentifier,
                       applePayRequest.countryCode,
                       applePayRequest.currencyCode,
                       applePayRequest.supportedNetworks.map({ $0.rawValue }).joined(separator: ","),
                       applePayRequest.paymentSummaryItems.count,
                       PKPaymentAuthorizationViewController.canMakePayments() ? "true" : "false",
                       PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: applePayRequest.supportedNetworks) ? "true" : "false")
                NISdkLogger.trace("""
                                  applePay — PKPaymentAuthorizationViewController returned nil; the sheet cannot \
                                  be shown. merchantIdentifier: \(applePayRequest.merchantIdentifier), \
                                  countryCode: \(applePayRequest.countryCode), \
                                  currencyCode: \(applePayRequest.currencyCode), \
                                  supportedNetworks: \(applePayRequest.supportedNetworks.map({ $0.rawValue }).joined(separator: ",")), \
                                  summaryItems: \(applePayRequest.paymentSummaryItems.count), \
                                  canMakePayments: \(PKPaymentAuthorizationViewController.canMakePayments()), \
                                  canMakePaymentsUsingNetworks: \(PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: applePayRequest.supportedNetworks))
                                  """)
            } else {
                os_log("[NISdk] applePay — no PKPaymentRequest was supplied to the SDK", log: NISdkLogger.payment, type: .error)
                NISdkLogger.trace("applePay — no PKPaymentRequest was supplied to the SDK")
            }
            self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
            break
        case .ThreeDSTwo:
            self.handlePaymentResponse(self.paymentResponse)
            break
        case .SavedCard:
            if let savedCard = order.savedCard, let amount = order.amount {
                if savedCard.recaptureCsc {
                    let savedCardViewController = SavedCardViewController(
                        makeSaveCardPaymentCallback: self.makeSavedCardPayment,
                        savedCard: savedCard,
                        orderAmount: amount,
                        order: order,
                        onCancel: {
                            [weak self] in
                            if NISdk.sharedInstance.shouldShowCancelAlert {
                                self?.showCancelPaymentAlert(with: .PaymentCancelled, and: nil, and: nil)
                            } else {
                                self?.finishPaymentAndClosePaymentViewController(with: .PaymentCancelled, and: nil, and: nil)
                            }
                        })
                    self.transition(to: .renderCardPaymentForm(savedCardViewController))
                } else {
                    makeSavedCardPayment(
                        SavedCardRequest(
                            expiry: savedCard.expiry,
                            cardholderName: savedCard.cardholderName,
                            cardToken: savedCard.cardToken,
                            cvv: nil))
                }
            } else {
                finishPaymentAndClosePaymentViewController(with: .InValidRequest, and: nil, and: .AuthFailed)
            }
            break
        }
    }

    lazy private var handleApplePayAuthorization: OnAuthorizeApplePayCallback  = {
        [unowned self] payment, completion in
        // The Apple Pay sheet was presented without waiting for authorization. Now that
        // the user has authorized, ensure the access token has arrived (it almost always
        // has, during the Face/Touch ID step) before posting the Apple Pay response.
        self.whenApplePayAuthResolved { authSucceeded in
            guard authSucceeded, let accessToken = self.accessToken else {
                // Authorization failed or its token never arrived — fail the Apple Pay
                // sheet gracefully rather than crashing on a missing token.
                os_log("[NISdk] applePay — authorization unavailable at authorize time, failing sheet", log: NISdkLogger.payment, type: .error)
                NISdkLogger.trace("applePay — user authorized but access token unavailable; failing sheet")
                if let completion = completion {
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil), nil)
                } else {
                    self.handlePaymentResponse(nil)
                }
                return
            }
            self.getPayerIp() { (payerIp) -> () in
                if let payment = payment, let completion = completion {
                    self.transactionService.postApplePayResponse(for: self.order,
                                                                 with: payment,
                                                                 using: accessToken,
                                                                 payerIp: payerIp, on: {
                        [unowned self] data, response, error in
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                        if let data = data {
                            do {
                                let paymentResponse: PaymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                                os_log("[NISdk] makeApplePayment — HTTP %d, state: %{public}@",
                                       log: NISdkLogger.payment, type: .info, statusCode, paymentResponse.state)
                                NISdkLogger.trace("makeApplePayment — HTTP \(statusCode), state: \(paymentResponse.state)")
                                if(paymentResponse.state == "AUTHORISED" || paymentResponse.state == "CAPTURED" || paymentResponse.state == "PURCHASED" || paymentResponse.state == "VERIFIED" || paymentResponse.state == "POST_AUTH_REVIEW") {
                                    completion(PKPaymentAuthorizationResult(status: .success, errors: nil), paymentResponse)
                                } else {
                                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil), paymentResponse)
                                }
                            } catch let error {
                                os_log("[NISdk] makeApplePayment — HTTP %d, failed to decode payment response: %{public}@, body: %{public}@",
                                       log: NISdkLogger.payment, type: .error, statusCode, error.localizedDescription,
                                       String(data: data.prefix(512), encoding: .utf8) ?? "<non-utf8>")
                                NISdkLogger.trace("makeApplePayment — HTTP \(statusCode) decode FAILED: \(String(data: data.prefix(512), encoding: .utf8) ?? "<non-utf8>")")
                                completion(PKPaymentAuthorizationResult(status: .failure, errors: nil), nil)
                            }
                        } else {
                            // No body at all — a transport error, or postApplePayResponse bailing
                            // because the order had no applePayLink. Previously this branch did
                            // nothing, so PassKit's completion handler was never invoked and the
                            // Apple Pay sheet span forever with no way out. Always complete.
                            os_log("[NISdk] makeApplePayment — no response data (HTTP %d), error: %{public}@ — failing the sheet",
                                   log: NISdkLogger.payment, type: .error, statusCode, error?.localizedDescription ?? "none")
                            NISdkLogger.trace("makeApplePayment — NO RESPONSE DATA (HTTP \(statusCode)), error: \(error?.localizedDescription ?? "none")")
                            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil), nil)
                        }
                    })
                } else {
                    self.handlePaymentResponse(nil)
                }
            }
        }
    }

    lazy private var makePayment = { (paymentRequest: PaymentRequest) in
        // 3. Make Payment
        self.getPayerIp() { (payerIp) -> () in
            paymentRequest.payerIp = payerIp

            self.getVisaPlans(visaEligibilityRequets: VisaEligibilityRequets(cardToken: nil, pan: paymentRequest.pan), onResponse: { visaPlan in
                if let plans = visaPlan, let fullAmount = self.order.amount, let cardNumber = paymentRequest.pan {
                    if (plans.matchedPlans.isEmpty) {
                        self.makeCardPayment(paymentRequest: paymentRequest)
                    } else {
                        DispatchQueue.main.async {
                            self.transition(to: .renderCardPaymentForm(VisaInstallmentViewController(visaPlan: plans, fullAmount: fullAmount, cardNumber: cardNumber, onMakePayment: { visaRequest in
                                paymentRequest.visaRequest = visaRequest
                                self.makeCardPayment(paymentRequest: paymentRequest)
                            }, onCancel: {
                                [weak self] in
                                if NISdk.sharedInstance.shouldShowCancelAlert {
                                    self?.showCancelPaymentAlert(with: .PaymentCancelled, and: nil, and: nil)
                                } else {
                                    self?.finishPaymentAndClosePaymentViewController(with: .PaymentCancelled, and: nil, and: nil)
                                }
                            })))
                        }
                    }
                } else {
                    self.makeCardPayment(paymentRequest: paymentRequest)
                }
            })
        }
    }

    private func makeCardPayment(paymentRequest: PaymentRequest) {
        self.transactionService.makePayment(for: self.order, with: paymentRequest, using: self.paymentToken!, on: {
            data, response, err in
            if err != nil {
                self.handlePaymentResponse(nil)
            } else if let data = data {
                do {
                    let paymentResponse: PaymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                    // 4. Intermediatory checks for payment failure attempts and anything else
                    self.handlePaymentResponse(paymentResponse)
                } catch {
                    os_log("[NISdk] makeCardPayment — failed to decode payment response: %{public}@", log: NISdkLogger.payment, type: .error, error.localizedDescription)
                    self.handlePaymentResponse(nil)
                }
            }
        })
    }

    lazy private var makeSavedCardPayment = { (savedCardRequest: SavedCardRequest) in
        // 3. Make Payment
        self.getPayerIp() { (payerIp) -> () in
            savedCardRequest.payerIp = payerIp

            if let savedCardUrl = self.order.embeddedData?.getSavedCardLink(), let accessToken = self.accessToken, let cardToken = self.order.savedCard?.cardToken, let cardNumber = self.order.savedCard?.maskedPan {
                if let matchedCandidates: [MatchedCandidate] = self.order.visSavedCardMatchedCandidates?.matchedCandidates, let candidate = matchedCandidates.first(where: { $0.cardToken == cardToken }) {
                    if candidate.eligibilityStatus == "MATCHED" {
                        self.getVisaPlans(visaEligibilityRequets: VisaEligibilityRequets(cardToken: cardToken, pan: nil), onResponse: { visaPlan in
                            if let plans = visaPlan, let fullAmount = self.order.amount {
                                if (plans.matchedPlans.isEmpty) {
                                    self.doSavedCardPayment(savedCardUrl: savedCardUrl, savedCardRequest: savedCardRequest, accessToken: accessToken)
                                } else {
                                    DispatchQueue.main.async {
                                        self.transition(to: .renderCardPaymentForm(VisaInstallmentViewController(visaPlan: plans, fullAmount: fullAmount, cardNumber: cardNumber, onMakePayment: { visaRequest in
                                            savedCardRequest.visaRequest = visaRequest
                                            self.doSavedCardPayment(savedCardUrl: savedCardUrl, savedCardRequest: savedCardRequest, accessToken: accessToken)
                                        }, onCancel: {
                                            [weak self] in
                                            if NISdk.sharedInstance.shouldShowCancelAlert {
                                                self?.showCancelPaymentAlert(with: .PaymentCancelled, and: nil, and: nil)
                                            } else {
                                                self?.finishPaymentAndClosePaymentViewController(with: .PaymentCancelled, and: nil, and: nil)
                                            }
                                        })))
                                    }
                                }
                            } else {
                                self.doSavedCardPayment(savedCardUrl: savedCardUrl, savedCardRequest: savedCardRequest, accessToken: accessToken)
                            }
                        })
                    } else {
                        self.doSavedCardPayment(savedCardUrl: savedCardUrl, savedCardRequest: savedCardRequest, accessToken: accessToken)
                    }
                } else {
                    self.doSavedCardPayment(savedCardUrl: savedCardUrl, savedCardRequest: savedCardRequest, accessToken: accessToken)
                }
            }
        }
    }

    private func doSavedCardPayment(savedCardUrl: String, savedCardRequest: SavedCardRequest, accessToken: String) {
        self.transactionService.doSavedCardPayment(
            for: savedCardUrl,
            with: savedCardRequest,
            using: accessToken,
            on: {
                data, response, error in
                if error != nil {
                    self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
                } else if let data = data {
                    do {
                        let paymentResponse: PaymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                        self.handlePaymentResponse(paymentResponse)
                    } catch {
                        os_log("[NISdk] doSavedCardPayment — failed to decode payment response: %{public}@", log: NISdkLogger.payment, type: .error, error.localizedDescription)
                        self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
                    }
                }
            })
    }

    func getPayerIp(onCompletion: @escaping (String?) -> ()) {
        guard let url = order.orderLinks?.payPageLink, let urlHost = URL(string: url)?.host else {
            onCompletion(nil)
            return
        }
        let ipUrl = "https://\(urlHost)/api/requester-ip"
        self.transactionService.getPayerIp(with: ipUrl, on: { payerIPData, _, _ in
            if let payerIPData = payerIPData {
                do {
                    let payerIpDict: [String: String] = try JSONDecoder().decode([String: String].self, from: payerIPData)
                    onCompletion(payerIpDict["requesterIp"])
                } catch {
                    onCompletion(nil)
                }
            } else {
                onCompletion(nil)
            }
        })
    }

    lazy private var handlePaymentResponse: (PaymentResponse?) -> Void = {
        paymentResponse in
        DispatchQueue.main.async {
            guard let paymentResponse = paymentResponse else {
                os_log("[NISdk] handlePaymentResponse — nil response, treating as failure", log: NISdkLogger.payment, type: .error)
                NISdkLogger.trace("handlePaymentResponse — nil response (sheet dismissed without a payment result), treating as failure")
                self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
                return
            }
            os_log("[NISdk] handlePaymentResponse — state: %{public}@", log: NISdkLogger.payment, type: .info, paymentResponse.state ?? "unknown")
            NISdkLogger.trace("handlePaymentResponse — state: \(paymentResponse.state)")
            if(paymentResponse.state == "AUTHORISED" || paymentResponse.state == "CAPTURED" || paymentResponse.state == "PURCHASED" || paymentResponse.state == "VERIFIED") {
                // 5. Close Screen if payment is done
                self.finishPaymentAndClosePaymentViewController(with: .PaymentSuccess, and: nil, and: nil)
                return
            }
            if (paymentResponse.state == "POST_AUTH_REVIEW") {
                self.finishPaymentAndClosePaymentViewController(with: .PaymentPostAuthReview, and: nil, and: nil)
                return
            }
            if(paymentResponse.state == "AWAIT_3DS") {
                os_log("[NISdk] handlePaymentResponse — initiating 3DS challenge", log: NISdkLogger.payment, type: .info)
                self.cardPaymentDelegate?.threeDSChallengeDidBegin?()
                self.initiateThreeDS(with: paymentResponse)
                return
            }
            if (paymentResponse.state == "AWAITING_PARTIAL_AUTH_APPROVAL") {
                os_log("[NISdk] handlePaymentResponse — initiating partial auth", log: NISdkLogger.payment, type: .info)
                self.cardPaymentDelegate?.partialAuthBegin?()
                do {
                    let partialAuthArgs = try paymentResponse.toPartialAuthArgs(accessToken: self.accessToken)
                    self.initiatePartialAuth(partialAuthArgs: partialAuthArgs)
                } catch {
                    os_log("[NISdk] handlePaymentResponse — partial auth args invalid: %{public}@", log: NISdkLogger.payment, type: .error, error.localizedDescription)
                    self.cardPaymentDelegate?.paymentDidComplete(with: .InValidRequest)
                }
                return
            }
            if (paymentResponse.state == "FAILED") {
                self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
                return
            }
            os_log("[NISdk] handlePaymentResponse — unhandled state '%{public}@', failing payment", log: NISdkLogger.payment, type: .error, paymentResponse.state)
            self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
        }
    }

    private func initiatePartialAuth(partialAuthArgs: PartialAuthArgs) {
        self.transition(to: .renderCardPaymentForm(
            PartialAuthViewController(
                partialAuthArgs: partialAuthArgs,
                onSuccess: {
                    self.finishPaymentAndClosePaymentViewController(with: .PaymentSuccess, and: nil, and: nil)
                },
                onFailed: {
                    self.finishPaymentAndClosePaymentViewController(with: .PartialAuthDeclineFailed, and: nil, and: nil)
                },
                onDecline: {
                    self.finishPaymentAndClosePaymentViewController(with: .PartialAuthDeclined, and: nil, and: nil)
                },
                onPartialAuth:  {
                    self.finishPaymentAndClosePaymentViewController(with: .PartiallyAuthorised, and: nil, and: nil)
                }
            )
        ))
    }

    private func initiateThreeDS(with paymentRepsonse: PaymentResponse) {
        if let acsUrl = paymentRepsonse.threeDSConfig?.acsUrl,
           let acsPaReq = paymentRepsonse.threeDSConfig?.acsPaReq,
           let acsMd = paymentRepsonse.threeDSConfig?.acsMd,
           let threeDSTermURL = paymentRepsonse.paymentLinks?.threeDSTermURL {
            let threeDSViewController = ThreeDSViewController(with: acsUrl,
                                                              acsPaReq: acsPaReq,
                                                              acsMd: acsMd,
                                                              threeDSTermURL: threeDSTermURL,
                                                              completion: onThreeDSCompletion)
            self.transition(to: .renderThreeDSChallengeForm(threeDSViewController))
        } else if let accessToken = self.accessToken {
            // Start threeds two
            let threeDSTwoViewController = ThreeDSTwoViewController(with: paymentRepsonse,
                                                                    accessToken: accessToken,
                                                                    transactionService: self.transactionService,
                                                                    completion: onThreeDSCompletion)
            threeDSTwoViewController.paypageLink = order.orderLinks?.payPageLink ?? ""
            // Surface a clear, machine-readable reason (e.g. THREE_DS_ACS_LOAD_TIMEOUT)
            // to the merchant when the SDK terminates the challenge early. The
            // customer-facing result still arrives via paymentDidComplete(with:).
            threeDSTwoViewController.onSDKFailure = { [weak self] errorCode in
                self?.cardPaymentDelegate?.threeDSChallengeDidFail?(withErrorCode: errorCode)
            }
            self.transition(to: .renderThreeDSChallengeForm(threeDSTwoViewController))
        } else {
            self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: .ThreeDSFailed, and: nil)
        }
    }

    lazy private var onThreeDSCompletion: (Bool) -> Void = { [weak self] hasSDKError in
        if(hasSDKError) {
            self?.handlePaymentResponse(nil)
            return
        }
        self?.transactionService.getOrder(for: (self?.order.orderLinks?.orderLink)!, using: self!.accessToken!, with:
                                                { (data, response, error) in
            if let data = data {
                do {
                    let orderResponse: OrderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
                    if let state = orderResponse.embeddedData?.payment?.first?.state {
                        if state == "AWAITING_PARTIAL_AUTH_APPROVAL" {
                            DispatchQueue.main.async {
                                do {
                                    self?.initiatePartialAuth(partialAuthArgs: try orderResponse.toPartialAuthArgs(accessToken: self?.accessToken))
                                } catch {
                                    self?.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
                                }
                            }
                            return
                        }
                    }
                    var successfulPayments: [PaymentResponse] = []
                    var awaitThreedsPayments: [PaymentResponse] = []
                    if let paymentResponses = orderResponse.embeddedData?.payment {
                        successfulPayments = paymentResponses.filter({ (paymentAttempt: PaymentResponse) -> Bool in
                            return paymentAttempt.state == "CAPTURED" || paymentAttempt.state == "AUTHORISED" || paymentAttempt.state == "PURCHASED" || paymentAttempt.state == "VERIFIED" || paymentAttempt.state == "POST_AUTH_REVIEW"
                        })

                        awaitThreedsPayments = paymentResponses.filter({ (paymentAttempt: PaymentResponse) -> Bool in
                            return paymentAttempt.state == "AWAIT_3DS"
                        })
                    }

                    if(successfulPayments.count > 0) {
                        self?.handlePaymentResponse(successfulPayments[0])
                    } else if(awaitThreedsPayments.count > 0) {
                        // we are still waiting for 3ds to complete
                        return
                    } else {
                        self?.handlePaymentResponse(nil)
                    }
                } catch let error {
                    os_log("[NISdk] onThreeDSCompletion — failed to decode order response: %{public}@", log: NISdkLogger.payment, type: .error, error.localizedDescription)
                    self?.handlePaymentResponse(nil)
                }
            }
        })
    }

    // This is called when payment is done(fail or success) with 3ds(fail or success) or without 3ds
    private func finishPaymentAndClosePaymentViewController(with paymentStatus: PaymentStatus,
                                                            and threeDSStatus: ThreeDSStatus?,
                                                            and authStatus: AuthorizationStatus?) {
        os_log("[NISdk] finishPayment — status: %{public}@, 3ds: %{public}@, auth: %{public}@",
               log: NISdkLogger.payment, type: .info,
               paymentStatus.rawVal,
               threeDSStatus.map { $0.rawVal } ?? "none",
               authStatus.map { $0.rawVal } ?? "none")
        // This is the status the host app receives from paymentDidComplete(with:), so it
        // is the line to line up against whatever the merchant's JS reports.
        NISdkLogger.trace("""
                          finishPayment — status: \(paymentStatus.rawVal), \
                          3ds: \(threeDSStatus.map { $0.rawVal } ?? "none"), \
                          auth: \(authStatus.map { $0.rawVal } ?? "none")
                          """)
        DispatchQueue.main.async { // Use the main thread to update any UI
            if let threeDSStatus = threeDSStatus {
                self.cardPaymentDelegate?.threeDSChallengeDidComplete?(with: threeDSStatus)
            }

            if let authStatus = authStatus  {
                self.cardPaymentDelegate?.authorizationDidComplete?(with: authStatus)
            }

            self.closePaymentViewController(completion: {
                [weak self] in
                self?.cardPaymentDelegate?.paymentDidComplete(with: paymentStatus)
            })
        }
    }

    private func closePaymentViewController(completion: (() -> Void)?) {
        dismiss(animated: true, completion: completion)
    }
}

private extension PaymentViewController {
    enum State {
        case authorizing
        case renderCardPaymentForm(UIViewController)
        case renderThreeDSChallengeForm(UIViewController)
    }

    private func transition(to newState: State) {
        shownViewController?.remove()
        let vc = viewController(for: newState)
        add(vc, inside: view)
        shownViewController = vc
        state = newState
    }

    func viewController(for state: State) -> UIViewController {
        switch state {
        case .authorizing:
            return AuthorizationViewController()

        case .renderCardPaymentForm(let viewController),
                .renderThreeDSChallengeForm(let viewController):
            return viewController
        }
    }
}

private extension PaymentViewController {
    private func showCancelPaymentAlert(with paymentStatus: PaymentStatus,
                                        and threeDSStatus: ThreeDSStatus?,
                                        and authStatus: AuthorizationStatus?) {
        let alertController = UIAlertController(
            title: "Cancel Payment Title".localized,
            message: "Cancel Payment Message".localized,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "Cancel Alert".localized, style: .cancel))
        alertController.addAction(UIAlertAction(title: "Cancel Confirm".localized, style: .destructive) { _ in
            self.finishPaymentAndClosePaymentViewController(with: paymentStatus, and: threeDSStatus, and: authStatus)
            self.dismiss(animated: true, completion: nil)
        })

        present(alertController, animated: true, completion: nil)
    }
}

private extension PaymentViewController {
    func getVisaPlans(visaEligibilityRequets: VisaEligibilityRequets, onResponse: @escaping (VisaPlans?) -> Void) {
        if let selfLink = self.order.embeddedData?.getSelfLink(), let accessToken = self.accessToken {
            self.transactionService.getVisaPlans(
                with: selfLink,
                using: accessToken,
                cardToken: visaEligibilityRequets.cardToken,
                cardNumber: visaEligibilityRequets.pan,
                on: { data, response, err in
                    if err != nil {
                        onResponse(nil)
                    } else if let data = data {
                        do {
                            let visaPlans: VisaPlans = try JSONDecoder().decode(VisaPlans.self, from: data)
                            onResponse(visaPlans)
                        } catch _ {
                            onResponse(nil)
                        }
                    }
                })
        } else {
            onResponse(nil)
        }
    }
}
