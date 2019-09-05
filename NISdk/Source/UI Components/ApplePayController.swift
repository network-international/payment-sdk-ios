//
//  ApplePayDelegate.swift
//  NISdk
//
//  Created by Johnny Peter on 14/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

typealias OnPostApplePayResponseCallback = (PKPaymentAuthorizationResult) -> Void
typealias OnAuthorizeApplePayCallback = (PKPayment?, OnPostApplePayResponseCallback?) -> Void

class ApplePayController: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    let onAuthorizeApplePayCallback: OnAuthorizeApplePayCallback
    let order: OrderResponse
    
    init(applePayDelegate: ApplePayDelegate,
         order: OrderResponse,
         onAuthorizeApplePayCallback: @escaping OnAuthorizeApplePayCallback) {
        self.order = order
        self.onAuthorizeApplePayCallback = onAuthorizeApplePayCallback
        super.init()
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelect paymentMethod: PKPaymentMethod,
                                            handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) {
        completion(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelect shippingMethod: PKShippingMethod,
                                            handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        completion(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: []))
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelectShippingContact contact: PKContact,
                                            handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
        completion(PKPaymentRequestShippingContactUpdate(errors: nil,
                                                         paymentSummaryItems: [],
                                                         shippingMethods: []))
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        self.onAuthorizeApplePayCallback(payment, {
            authorizationResult in
            completion(authorizationResult)
            controller.dismiss(animated: false, completion: nil)
        })
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: false, completion: {
            self.onAuthorizeApplePayCallback(nil, nil)
        })
    }
}
