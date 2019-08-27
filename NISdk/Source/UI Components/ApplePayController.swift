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
typealias OnAuthorizeApplePayCallback = (PKPayment, @escaping OnPostApplePayResponseCallback) -> Void

class ApplePayController: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    
    var pkPaymentAuthorizationVC: PKPaymentAuthorizationViewController?
    let applePayPaymentRequest: PKPaymentRequest
    let onAuthorizeApplePayCallback: OnAuthorizeApplePayCallback
    let order: OrderResponse
    
    init(applePayPaymentRequest: PKPaymentRequest,
         applePayDelegate: ApplePayDelegate,
         order: OrderResponse,
         onAuthorizeApplePayCallback: @escaping OnAuthorizeApplePayCallback) {
        
        self.order = order
        self.applePayPaymentRequest = applePayPaymentRequest
        if let allowedPKPaymentNetworks = order.paymentMethods?.card?.map({ $0.pkNetworkType }) {
            self.applePayPaymentRequest.supportedNetworks = Array(Set(allowedPKPaymentNetworks))
        }
        self.pkPaymentAuthorizationVC = PKPaymentAuthorizationViewController(paymentRequest: applePayPaymentRequest)
        self.onAuthorizeApplePayCallback = onAuthorizeApplePayCallback
        super.init()
        self.pkPaymentAuthorizationVC?.delegate = self
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelect paymentMethod: PKPaymentMethod,
                                            handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) {
        
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelect shippingMethod: PKShippingMethod,
                                            handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelectShippingContact contact: PKContact,
                                            handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
        
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        self.onAuthorizeApplePayCallback(payment, {
            authorizationResult in
            completion(authorizationResult)
        })
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        
    }
}
