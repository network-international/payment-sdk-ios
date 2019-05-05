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
        
    }
    
    func applePayShippingMethodUpdated(didSelect shippingMethod: PKShippingMethod, handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        
    }
    
    func applePayContactUpdated(didSelect shippingContact: PKContact, handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
        
    }
    
    
}
