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
    private weak var shownViewController: UIViewController?
    
    private let transactionService = TransactionServiceAdapter()
    private weak var cardPaymentDelegate: CardPaymentDelegate?
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
        cardPaymentDelegate?.authorizationDidComplete(with: .AuthFailed)
        closePaymentViewController()
    }
    
    func authorizePayment() {
        cardPaymentDelegate?.authorizationDidBegin?()
        self.transition(to: .authorizing)
        if let authCode = order.getAuthCode(),
            let paymentLink = order.orderLinks?.paymentAuthorizationLink {
            transactionService.authorizePayment(for: authCode, using: paymentLink, on: {
                [weak self] paymentToken in
                if let paymentToken = paymentToken {
                    // Callback hell...
                    self?.paymentToken = paymentToken
                    // 2. Show card payment screen after authorization (payment token is received)
                     DispatchQueue.main.async { // Use the main thread to update any UI
                        let cardPaymentViewController = CardPaymentViewController(makePaymentCallback: self?.makePayment)
                        self?.cardPaymentDelegate?.authorizationDidComplete(with: .AuthSuccess)
                        self?.cardPaymentDelegate?.paymentDidBegin?()
                        self?.transition(to: .renderCardPaymentForm(cardPaymentViewController))
                    }
                } else {
                    DispatchQueue.main.async { // Use the main thread to update any UI
                     // Close payment view controller if paymentToken could not be fetched
                        self?.endAuthAndClosePaymentController()
                    }
                }
            })
        } else {
            // Close payment view controller if authCode or payment link is broken
           endAuthAndClosePaymentController()
        }
    }
    
    private func makePayment(paymentRequest: PaymentRequest) -> Void {
        // 3. Make Payment
        transactionService.makePayment(for: order, with: paymentRequest, using: paymentToken!, on: {
            [weak self] data, response, error in
            if let data = data {
                do {
                    let paymentResponse: PaymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                    // 4. Intermediatory checks for payment failure attempts and anything else
                    DispatchQueue.main.async {
                        if(paymentResponse.state == "AUTHORISED") {
                            // 5. Close Screen if payment is done
                            self?.cardPaymentDelegate?.paymentDidComplete(with: .PaymentSuccess)
                            self?.closePaymentViewController()
                            
                        } else {
                            self?.cardPaymentDelegate?.paymentDidComplete(with: .PaymentFailed)
                            self?.closePaymentViewController()
                        }
                    }
                } catch let error {
                    print(error)
                }
            }
        })
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
