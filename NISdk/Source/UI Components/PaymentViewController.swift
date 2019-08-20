//
//  PaymentViewController.swift
//  NISdk
//
//  Created by Johnny Peter on 19/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

typealias MakePaymentCallback = (PaymentRequest) -> Void

class PaymentViewController: UIViewController {
    private var state: State?
    private var shownViewController: UIViewController?
    
    private let transactionService = TransactionServiceAdapter()
    private let cardPaymentDelegate: CardPaymentDelegate
    private let order: OrderResponse
    private var paymentToken: String?
    
    init(order: OrderResponse, and cardPaymentDelegate: CardPaymentDelegate) {
        self.order = order
        self.cardPaymentDelegate = cardPaymentDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Perform authorization by aquiring a payment token
        self.authorizePayment()
    }
    
    // This is called when authorization fails
    func endAuthAndClosePaymentController() {
        cardPaymentDelegate.authorizationDidComplete(with: .AuthFailed)
        closePaymentViewController()
    }
    
    func authorizePayment() {
        cardPaymentDelegate.authorizationDidBegin?()
        self.transition(to: .authorizing)
        if let authCode = order.getAuthCode(),
            let paymentLink = order.orderLinks?.paymentAuthorizationLink {
            transactionService.authorizePayment(for: authCode, using: paymentLink, on: {
                paymentToken in
                if let paymentToken = paymentToken {
                    // Callback hell...
                    self.paymentToken = paymentToken
                    // 2. Show card payment screen after authorization (payment token is received)
                    let cardPaymentViewController = CardPaymentViewController(makePaymentCallback: self.makePayment)
                    self.cardPaymentDelegate.authorizationDidComplete(with: .AuthSuccess)
                    self.cardPaymentDelegate.paymentDidBegin?()
                    DispatchQueue.main.async { // Use the main thread to update any UI
                        self.transition(to: .renderCardPaymentForm(cardPaymentViewController))
                    }
                } else {
                     // Close payment view controller if paymentToken could not be fetched
                    self.endAuthAndClosePaymentController()
                }
            })
        } else {
            // Close payment view controller if authCode or payment link is broken
           endAuthAndClosePaymentController()
        }
    }
    
    private func makePayment(paymentRequest: PaymentRequest) -> Void {
        // 3. Make Payment
        
        /* payment token below is safely force unwrapped
         as its gauranteed to contain a value else
         the vc would have been closed */
        transactionService.makePayment(for: order, with: paymentRequest, using: paymentToken!, on: {
            data, response, error in
            
        })
        // 4. Intermediatory checks for payment failure attempts and anything else
        // 5. Close Screen if payment is done
    }
    
    private func closePaymentViewController() {
        dismiss(animated: true, completion: nil)
    }
}

private extension PaymentViewController {
    enum State {
        case authorizing
        case renderCardPaymentForm(UIViewController)
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
            
        case .renderCardPaymentForm(let viewController):
            return viewController
        }
    }
}
