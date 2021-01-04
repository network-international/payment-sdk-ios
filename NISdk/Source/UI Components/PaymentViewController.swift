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

class PaymentViewController: UIViewController {
    private var state: State?
    private weak var shownViewController: UIViewController?
    
    private let transactionService = TransactionServiceAdapter()
    private weak var cardPaymentDelegate: CardPaymentDelegate?
    private let order: OrderResponse
    private var paymentToken: String?
    private var accessToken: String?
    private let paymentMedium: PaymentMedium
    private var applePayController: ApplePayController?
    private var applePayDelegate: ApplePayDelegate?
    var applePayRequest: PKPaymentRequest?
    
    init(order: OrderResponse, cardPaymentDelegate: CardPaymentDelegate,
         applePayDelegate: ApplePayDelegate?, paymentMedium: PaymentMedium) {
        self.order = order
        self.cardPaymentDelegate = cardPaymentDelegate
        self.paymentMedium = paymentMedium
        if let applePayDelegate = applePayDelegate {
            self.applePayDelegate = applePayDelegate
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.performPreAuthChecksAndBeginAuth()
    }
    
    // Perform any checks that need to be done before auth
    private func performPreAuthChecksAndBeginAuth() {
        // Apple pay is not enabled by merchant, hence abort payment flow
        if(self.paymentMedium == .ApplePay && (self.order.embeddedData?.payment?[0].paymentLinks?.applePayLink) == nil) {
            self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: .ThreeDSFailed, and: .AuthFailed);
            return
        }
        // 1. Perform authorization by aquiring a payment token
        self.authorizePayment()
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
            let cardPaymentViewController = CardPaymentViewController(makePaymentCallback: self.makePayment, order: order, onCancel: {
                [weak self] in
                self?.finishPaymentAndClosePaymentViewController(with: .PaymentCancelled, and: nil, and: nil)
            })
            self.transition(to: .renderCardPaymentForm(cardPaymentViewController))
            break;
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
        }
    }
    
    lazy private var handleApplePayAuthorization: OnAuthorizeApplePayCallback  = {
        [unowned self] payment, completion in
        if let payment = payment, let completion = completion {
            self.transactionService.postApplePayResponse(for: self.order,
                 with: payment,
                 using: self.accessToken!, on: {
                    [unowned self] data, response, error in
                    if let data = data {
                        do {
                            let paymentResponse: PaymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                            if(paymentResponse.state == "AUTHORISED" || paymentResponse.state == "CAPTURED") {
                                completion(PKPaymentAuthorizationResult(status: .success, errors: nil), paymentResponse)
                            } else {
                                completion(PKPaymentAuthorizationResult(status: .failure, errors: nil), paymentResponse)
                            }
                        } catch let error {
                            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil), nil)
                        }
                    }
            })
        } else {
             self.handlePaymentResponse(nil)
        }
    }
    
    lazy private var makePayment = { [unowned self] paymentRequest in
        // 3. Make Payment
        self.transactionService.makePayment(for: self.order, with: paymentRequest, using: self.paymentToken!, on: {
            data, response, err in
            if err != nil {
                self.handlePaymentResponse(nil)
            } else if let data = data {
                do {
                    let paymentResponse: PaymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                    // 4. Intermediatory checks for payment failure attempts and anything else
                    self.handlePaymentResponse(paymentResponse)
                } catch let error {
                    self.handlePaymentResponse(nil)
                }
            }
        })
    }
    
    lazy private var handlePaymentResponse: (PaymentResponse?) -> Void = {
        paymentResponse in
        DispatchQueue.main.async {
            if let paymentResponse = paymentResponse {
                if(paymentResponse.state == "AUTHORISED" || paymentResponse.state == "CAPTURED") {
                    // 5. Close Screen if payment is done
                    self.finishPaymentAndClosePaymentViewController(with: .PaymentSuccess, and: nil, and: nil)
                } else if(paymentResponse.state == "AWAIT_3DS") {
                    self.cardPaymentDelegate?.threeDSChallengeDidBegin?()
                    self.initiateThreeDS(with: paymentResponse)
                } else {
                    self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
                }
            } else {
                self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: nil, and: nil)
            }
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
        } else {
            self.finishPaymentAndClosePaymentViewController(with: .PaymentFailed, and: .ThreeDSFailed, and: nil)
        }
    }
    
    lazy private var onThreeDSCompletion: () -> Void = { [weak self] in
        self?.transactionService.getOrder(for: (self?.order.orderLinks?.orderLink)!, using: self!.accessToken!, with:
            { (data, response, error) in
                if let data = data {
                    do {
                        let orderResponse: OrderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
                        var successfulPayments: [PaymentResponse] = []
                        var awaitThreedsPayments: [PaymentResponse] = []
                        if let paymentResponses = orderResponse.embeddedData?.payment {
                            successfulPayments = paymentResponses.filter({ (paymentAttempt: PaymentResponse) -> Bool in
                                return paymentAttempt.state == "CAPTURED" || paymentAttempt.state == "AUTHORISED"
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
