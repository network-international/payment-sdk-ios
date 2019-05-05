//
//  PaymentSDKDelegate.swift
//  UIHostApp
//
//  Created by Niraj Chauhan on 5/5/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PaymentSDK

final class PaymentSDKDelegate : PaymentDelegate {
    func beginAuthorization(didSelect paymentMethod: PaymentMethod, handler completion: @escaping (PaymentAuthorizationLink?) -> Void) {
        print("Create order")
        let amount = Amount(currencyCode: ViewController.currency, value: ViewController.cartTotal)
        OrderService.create(amount: amount, action: "AUTH"){
            (orderCreateResponse, e) in
            if let error = e {
                print(error)
                return
            }
            if let order = orderCreateResponse {
                let authLink = PaymentAuthorizationLink(href: order.paymentAuthorizationUrl, code: order.code)
                completion(authLink)
            }
            
        }
    }
    
    func authorizationStarted() {
        print("Auth started")
    }
    
    func authorizationCompleted(withStatus status: AuthorizationStatus) {
        print("Auth Completed with status \(status)")
    }
    
    func paymentStarted() {
        print("Payment started")
    }
    
    func paymentCompleted(with status: PaymentStatus) {
        print("Payment completed with status: \(status)")
    }
}
