//
//  ApplePayDelegate.swift
//  NISdk
//
//  Created by Johnny Peter on 27/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

@objc public protocol ApplePayDelegate {
    @objc optional func didSelectPaymentMethod(paymentMethod: PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate
    @objc optional func didSelectShippingMethod(shippingMethod: PKShippingMethod) -> PKPaymentRequestShippingMethodUpdate
    @objc optional func didSelectShippingContact(shippingContact: PKContact) -> PKPaymentRequestShippingContactUpdate
}
