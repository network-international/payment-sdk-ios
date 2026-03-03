//
//  PaymentViewController.swift
//  NISdk
//
//  Created by Johnny Peter on 19/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
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
    var clickToPayConfig: ClickToPayConfig?
    private weak var clickToPayDelegate: ClickToPayDelegate?
    var aaniBackLink: String?
    private var lastPaymentResponse: PaymentResponse?
    
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
        print("orderRef \(self.order.reference ?? "")")
        self.performPreAuthChecksAndBeginAuth()
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
        
        // Apple pay is not enabled by merchant, hence abort payment flow
        if(self.paymentMedium == .ApplePay && (self.order.embeddedData?.payment?[0].paymentLinks?.applePayLink) == nil) {
            self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: .ThreeDSFailed, and: .AuthFailed);
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
                    // 2. Show card payment screen after authorization (payment token is received)
                    DispatchQueue.main.async { // Use the main thread to update any UI
                        self?.cardPaymentDelegate?.authorizationDidComplete?(with: .AuthSuccess)
                        self?.cardPaymentDelegate?.paymentDidBegin?()
                        self?.initiatePaymentForm()
                    }
                } else {
                    self?.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: .AuthFailed)
                }
            })
        } else {
            // Close payment view controller if authCode or payment link is broken
            self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: .AuthFailed)
        }
    }
    
    private func initiatePaymentForm() {
        switch paymentMedium {
        case .Card:
            let unifiedPaymentPage = UnifiedPaymentPageViewController(order: order, onCancel: {
                [weak self] in
                if NISdk.sharedInstance.shouldShowCancelAlert {
                    self?.showCancelPaymentAlert(with: .PaymentCancelled, and: nil, and: nil)
                } else {
                    self?.finishPaymentAndClosePaymentViewController(with: .PaymentCancelled, and: nil, and: nil)
                }
            })
            unifiedPaymentPage.makePaymentCallback = self.makePayment
            unifiedPaymentPage.onApplePayTapped = { [weak self] in
                self?.initiateApplePayFromUnifiedPage()
            }
            unifiedPaymentPage.onClickToPayTapped = { [weak self] in
                self?.initiateClickToPayFromUnifiedPage()
            }
            unifiedPaymentPage.onAaniTapped = { [weak self] in
                self?.initiateAaniFromUnifiedPage()
            }
            self.transition(to: .renderCardPaymentForm(unifiedPaymentPage))
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
                    pkPaymentAuthorizationVC.delegate = applePayController
                    self.shownViewController?.remove()
                    self.present(pkPaymentAuthorizationVC, animated: false, completion: nil)
                    return
                }
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
    
    private func initiateApplePayFromUnifiedPage() {
        print("ApplePay: initiateApplePayFromUnifiedPage called")
        guard let applePayRequest = applePayRequest, let applePayDelegate = applePayDelegate else {
            print("ApplePay: FAILED - applePayRequest is nil: \(self.applePayRequest == nil), applePayDelegate is nil: \(self.applePayDelegate == nil)")
            return
        }
        print("ApplePay: Creating ApplePayController")
        print("ApplePay: merchantIdentifier: \(applePayRequest.merchantIdentifier)")
        print("ApplePay: countryCode: \(applePayRequest.countryCode)")
        print("ApplePay: currencyCode: \(applePayRequest.currencyCode)")
        print("ApplePay: summaryItems: \(applePayRequest.paymentSummaryItems.map { "\($0.label): \($0.amount)" })")
        print("ApplePay: merchantCapabilities: \(applePayRequest.merchantCapabilities.rawValue)")
        print("ApplePay: applePayLink: \(order.embeddedData?.payment?[0].paymentLinks?.applePayLink ?? "nil")")

        applePayController = ApplePayController(applePayDelegate: applePayDelegate,
                                                order: order,
                                                onDismissCallback: handlePaymentResponse,
                                                onAuthorizeApplePayCallback: handleApplePayAuthorization)
        if let allowedPKPaymentNetworks = order.paymentMethods?.card?.map({ $0.pkNetworkType }) {
            let networks = Array(Set(allowedPKPaymentNetworks))
            applePayRequest.supportedNetworks = networks
            print("ApplePay: supportedNetworks: \(networks.map { $0.rawValue })")
        }
        let pkPaymentAuthorizationVC = PKPaymentAuthorizationViewController(paymentRequest: applePayRequest)
        if let pkPaymentAuthorizationVC = pkPaymentAuthorizationVC {
            pkPaymentAuthorizationVC.delegate = applePayController
            print("ApplePay: Presenting PKPaymentAuthorizationViewController")
            self.present(pkPaymentAuthorizationVC, animated: true, completion: {
                print("ApplePay: PKPaymentAuthorizationViewController presented successfully")
            })
        } else {
            print("ApplePay: FAILED - PKPaymentAuthorizationViewController init returned nil (invalid payment request)")
        }
    }

    private func initiateAaniFromUnifiedPage() {
        guard let backLink = aaniBackLink else { return }
        do {
            let aaniPayArgs = try order.toAaniPayArgs(backLink, accessToken: self.accessToken)
            if #available(iOS 14.0, *) {
                let aaniVC = AaniPayViewController(aaniPayArgs: aaniPayArgs) { [weak self] status in
                    switch status {
                    case .success:
                        self?.finishPaymentAndClosePaymentViewController(with: .PaymentSuccess, and: nil, and: nil)
                    case .cancelled:
                        // Stay on unified page
                        break
                    default:
                        self?.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
                    }
                }
                let navController = UINavigationController(rootViewController: aaniVC)
                navController.modalPresentationStyle = .pageSheet
                self.present(navController, animated: true)
            }
        } catch {
            print("Aani: Failed to build args - \(error)")
        }
    }

    private func initiateClickToPayFromUnifiedPage() {
        guard let config = clickToPayConfig else { return }

        do {
            let args = try self.order.toClickToPayArgs()
            let cookie = self.paymentToken.flatMap { "payment-token=\($0)" }

            // Create ClickToPayVC without email — it will check recognition
            // via getCards({}) first. If recognized, cards are shown directly.
            // If not, the in-page email entry appears (no second SDK init needed).
            let clickToPayVC = ClickToPayViewController(
                clickToPayConfig: config,
                clickToPayArgs: args,
                orderReference: self.order.reference,
                accessToken: self.accessToken,
                paymentCookie: cookie,
                userEmail: nil,
                onCompletion: { [weak self] status in
                    switch status {
                    case .success:
                        self?.finishPaymentAndClosePaymentViewController(with: .PaymentSuccess, and: nil, and: nil)
                    case .postAuthReview:
                        self?.finishPaymentAndClosePaymentViewController(with: .PaymentPostAuthReview, and: nil, and: nil)
                    case .failed:
                        self?.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
                    default:
                        // Click to Pay was cancelled, stay on unified page
                        break
                    }
                }
            )
            clickToPayVC.showCloseButton = true

            let navController = UINavigationController(rootViewController: clickToPayVC)
            navController.modalPresentationStyle = .pageSheet
            self.present(navController, animated: true)
        } catch {
            print("ClickToPay: Failed to build args - \(error)")
        }
    }

    lazy private var handleApplePayAuthorization: OnAuthorizeApplePayCallback  = {
        [unowned self] payment, completion in
        print("ApplePay: handleApplePayAuthorization called, payment: \(payment != nil), completion: \(completion != nil)")
        self.getPayerIp() { (payerIp) -> () in
            print("ApplePay: getPayerIp completed, payerIp: \(payerIp ?? "nil")")
            if let payment = payment, let completion = completion {
                print("ApplePay: Posting Apple Pay response, accessToken: \(self.accessToken != nil ? "present" : "nil")")
                print("ApplePay: applePayLink: \(self.order.embeddedData?.payment?[0].paymentLinks?.applePayLink ?? "nil")")
                self.transactionService.postApplePayResponse(for: self.order,
                                                             with: payment,
                                                             using: self.accessToken!,
                                                             payerIp: payerIp, on: {
                    [unowned self] data, response, error in
                    print("ApplePay: postApplePayResponse completed")
                    if let error = error {
                        print("ApplePay: postApplePayResponse ERROR: \(error)")
                    }
                    if let httpResponse = response as? HTTPURLResponse {
                        print("ApplePay: postApplePayResponse HTTP status: \(httpResponse.statusCode)")
                    }
                    if let data = data {
                        print("ApplePay: postApplePayResponse data size: \(data.count) bytes")
                        if let rawString = String(data: data, encoding: .utf8) {
                            print("ApplePay: postApplePayResponse raw: \(rawString.prefix(500))")
                        }
                        do {
                            let paymentResponse: PaymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                            print("ApplePay: Payment response state: \(paymentResponse.state ?? "nil")")
                            if(paymentResponse.state == "AUTHORISED" || paymentResponse.state == "CAPTURED" || paymentResponse.state == "PURCHASED" || paymentResponse.state == "VERIFIED" || paymentResponse.state == "POST_AUTH_REVIEW") {
                                print("ApplePay: Payment SUCCESS - completing with .success")
                                completion(PKPaymentAuthorizationResult(status: .success, errors: nil), paymentResponse)
                            } else {
                                print("ApplePay: Payment FAILED state: \(paymentResponse.state ?? "nil") - completing with .failure")
                                completion(PKPaymentAuthorizationResult(status: .failure, errors: nil), paymentResponse)
                            }
                        } catch let error {
                            print("ApplePay: Failed to decode payment response: \(error)")
                            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil), nil)
                        }
                    } else {
                        print("ApplePay: postApplePayResponse returned NO data")
                    }
                })
            } else {
                print("ApplePay: payment or completion is nil, calling handlePaymentResponse(nil)")
                self.handlePaymentResponse(nil)
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
                            if #available(iOS 13.0, *) {
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
                } catch _ {
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
                                        if #available(iOS 13.0, *) {
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
                    } catch _ {
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
        print("ApplePay/Payment: handlePaymentResponse called, state: \(paymentResponse?.state ?? "nil (no response)")")
        self.lastPaymentResponse = paymentResponse
        DispatchQueue.main.async {
            guard let paymentResponse = paymentResponse else {
                print("ApplePay/Payment: No payment response - finishing with PaymentFailed")
                self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
                return
            }
            if(paymentResponse.state == "AUTHORISED" || paymentResponse.state == "CAPTURED" || paymentResponse.state == "PURCHASED" || paymentResponse.state == "VERIFIED") {
                // 5. Close Screen if payment is done
                print("ApplePay/Payment: Payment successful - state: \(paymentResponse.state ?? "")")
                self.finishPaymentAndClosePaymentViewController(with: .PaymentSuccess, and: nil, and: nil)
                return
            }
            if (paymentResponse.state == "POST_AUTH_REVIEW") {
                print("ApplePay/Payment: Post auth review")
                self.finishPaymentAndClosePaymentViewController(with: .PaymentPostAuthReview, and: nil, and: nil)
                return
            }
            if(paymentResponse.state == "AWAIT_3DS") {
                print("ApplePay/Payment: 3DS required")
                self.cardPaymentDelegate?.threeDSChallengeDidBegin?()
                self.initiateThreeDS(with: paymentResponse)
                return
            }
            if (paymentResponse.state == "AWAITING_PARTIAL_AUTH_APPROVAL") {
                print("ApplePay/Payment: Partial auth approval required")
                self.cardPaymentDelegate?.partialAuthBegin?()
                do {
                    let partialAuthArgs = try paymentResponse.toPartialAuthArgs(accessToken: self.accessToken)
                    self.initiatePartialAuth(partialAuthArgs: partialAuthArgs)
                } catch {
                    self.cardPaymentDelegate?.paymentDidComplete(with: .InValidRequest)
                }
                return
            }
            print("ApplePay/Payment: Unhandled state: \(paymentResponse.state ?? "nil") - finishing with PaymentFailed")
            self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
        }
    }
    
    private func initiatePartialAuth(partialAuthArgs: PartialAuthArgs) {
        if #available(iOS 13.0, *) {
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
                    self?.handlePaymentResponse(nil)
                }
            }
        })
    }
    
    // This is called when payment is done(fail or success) with 3ds(fail or success) or without 3ds
    private func finishPaymentAndClosePaymentViewController(with paymentStatus: PaymentStatus,
                                                            and threeDSStatus: ThreeDSStatus?,
                                                            and authStatus: AuthorizationStatus?) {
        print("ApplePay/Payment: finishPaymentAndClosePaymentViewController - paymentStatus: \(paymentStatus), threeDSStatus: \(String(describing: threeDSStatus)), authStatus: \(String(describing: authStatus))")
        DispatchQueue.main.async { // Use the main thread to update any UI
            if let threeDSStatus = threeDSStatus {
                self.cardPaymentDelegate?.threeDSChallengeDidComplete?(with: threeDSStatus)
            }

            if let authStatus = authStatus  {
                self.cardPaymentDelegate?.authorizationDidComplete?(with: authStatus)
            }

            // Show result screen for success/failure statuses (only if not already on result screen)
            if paymentStatus == .PaymentSuccess || paymentStatus == .PaymentFailed {
                if case .renderPaymentResult = self.state {
                    // Already on result screen, skip
                } else if #available(iOS 14.0, *) {
                    self.showPaymentResultScreen(paymentStatus: paymentStatus, threeDSStatus: threeDSStatus, authStatus: authStatus)
                    return
                }
            }

            self.closePaymentViewController(completion: {
                [weak self] in
                self?.cardPaymentDelegate?.paymentDidComplete(with: paymentStatus)
            })
        }
    }

    @available(iOS 14.0, *)
    private func showPaymentResultScreen(paymentStatus: PaymentStatus,
                                          threeDSStatus: ThreeDSStatus?,
                                          authStatus: AuthorizationStatus?) {
        let isSuccess = paymentStatus == .PaymentSuccess
        let formattedAmount = self.order.amount?.getFormattedAmount()
        let transactionId = self.lastPaymentResponse?.reference ?? self.order.reference ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: NISdk.sharedInstance.sdkLanguage)
        dateFormatter.dateFormat = "dd MMM yyyy, hh:mm a"
        let dateTime = dateFormatter.string(from: Date())

        let args = PaymentResultArgs(
            isSuccess: isSuccess,
            amount: formattedAmount,
            transactionId: transactionId,
            dateTime: dateTime,
            cardProviders: self.order.paymentMethods?.card ?? []
        )

        let resultVC = PaymentResultViewController(args: args, onDone: { [weak self] in
            self?.closePaymentViewController(completion: {
                self?.cardPaymentDelegate?.paymentDidComplete(with: paymentStatus)
            })
        })

        self.transition(to: .renderPaymentResult(resultVC))
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
        case renderPaymentResult(UIViewController)
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
                .renderThreeDSChallengeForm(let viewController),
                .renderPaymentResult(let viewController):
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
