//
//  ApplePaySDKDelegate.swift
//  UIHostApp
//
//  Created by Niraj Chauhan on 5/5/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit
import PaymentSDK

final class ApplePaySDKDelegate : ApplePayDelegate{
    func applePayPaymentMethodUpdated(didSelect paymentMethod: PaymentMethod, handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) {
        print("Apple pay payment method updated: \(paymentMethod)")
        completion(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
    }
    
    func applePayShippingMethodUpdated(didSelect shippingMethod: PKShippingMethod, handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        print("Apple pay shipping method updated: \(shippingMethod)")
        completion(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: []))
    }
    
    func applePayContactUpdated(didSelect shippingContact: PKContact, handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
        print("Apple pay contact updated: \(shippingContact)")
        completion(PKPaymentRequestShippingContactUpdate(errors: nil,
                                                         paymentSummaryItems: [],
                                                         shippingMethods: []))
    }
    
    
}
