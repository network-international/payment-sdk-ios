//
//  ApplePayDelegate.swift
//  PaymentSDK
//
//  Created by Niraj Chauhan on 4/30/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

@objc public protocol ApplePayDelegate
{
    @objc func applePayPaymentMethodUpdated(didSelect paymentMethod: PaymentMethod,
                                      handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void)
    
    @objc func applePayShippingMethodUpdated(didSelect shippingMethod: PKShippingMethod,
                                       handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void)
    
    @objc func applePayContactUpdated(didSelect shippingContact: PKContact,
                                handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void)
    
}
