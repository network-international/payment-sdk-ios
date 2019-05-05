//
//  PaymentSDKHandler.swift
//  UIHostApp
//
//  Created by Niraj Chauhan on 5/5/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit
import PaymentSDK

final class PaymentSDKHandler{
    static let sharedInstance = PaymentSDKHandler()
    
    static let sdk = PaymentSDK.Interface.sharedInstance
    private var paymentDelegate : PaymentSDKDelegate?
    
    private init() {}
    
    static func configureSDK()
    {
        // For Apple Pay
        sdk.configure(with: Interface.Configuration(merchantIdentifier: "merchant.com.furniture.store.ni", merchantCapabilities: [.capabilityDebit, .capabilityCredit, .capability3DS]))
        // For only Card
        //        sdk.configure()
    }
    
    func showCardPaymentView(delegate: PaymentDelegate?, overParent parent: UIViewController, completion: @escaping VoidBlock){
        guard let paymentDelegate = delegate else
        {
            return
        }
        guard let paymentHandler = PaymentSDKHandler.sdk.paymentAuthorizationHandler else
        {
            return
        }
        paymentHandler.presentCardView(overParent: parent, withDelegate: paymentDelegate, completion: completion)
    }
    
    func showApplePayPaymentView(paymentDelegate: PaymentDelegate?, applePayDelegate: ApplePayDelegate?, overParent parent: UIViewController, request: PKPaymentRequest, items: [PKPaymentSummaryItem], completion: @escaping VoidBlock){
        guard let paymentDelegate = paymentDelegate else
        {
            return
        }
        guard let applePayDelegate = applePayDelegate else
        {
            return
        }
        guard let paymentHandler = PaymentSDKHandler.sdk.paymentAuthorizationHandler else
        {
            return
        }
        
        paymentHandler.presentApplePayView(overParent: parent, withDelegate: paymentDelegate, withApplePayDelegate: applePayDelegate, withRequest: request, items: items, completion: completion)
    }
    
}
