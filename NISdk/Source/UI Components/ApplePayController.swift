//
//  ApplePayDelegate.swift
//  NISdk
//
//  Created by Johnny Peter on 14/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

class ApplePayController: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    
    var applePayController: PKPaymentAuthorizationViewController?
    let applePayPaymentRequest: PKPaymentRequest
    
    init(applePayPaymentRequest: PKPaymentRequest) {
        self.applePayPaymentRequest = applePayPaymentRequest
    }
    
    func getController() -> UIViewController? {
        return applePayController
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
        
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        
    }
}
