//
//  ApplePayDelegate.swift
//  PaymentSDK
//
//  Created by Niraj Chauhan on 4/30/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

public protocol ApplePayDelegate : AnyObject
{
    func applePayPaymentMethodUpdated(didSelect paymentMethod: PaymentMethod,
                                      handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void)
    
    func applePayShippingMethodUpdated(didSelect shippingMethod: PKShippingMethod,
                                       handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void)
    
    func applePayContactUpdated(didSelect shippingContact: PKContact,
                                handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void)
    
}
