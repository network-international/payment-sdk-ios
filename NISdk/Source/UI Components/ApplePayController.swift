//
//  ApplePayDelegate.swift
//  NISdk
//
//  Created by Johnny Peter on 14/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

typealias OnPostApplePayResponseCallback = (PKPaymentAuthorizationResult, PaymentResponse?) -> Void
typealias OnAuthorizeApplePayCallback = (PKPayment?, OnPostApplePayResponseCallback?) -> Void

class ApplePayController: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    let onAuthorizeApplePayCallback: OnAuthorizeApplePayCallback
    let order: OrderResponse
    let onDismissCallback: (PaymentResponse?) -> Void
    let applePayDelegate: ApplePayDelegate
    
    init(applePayDelegate: ApplePayDelegate,
         order: OrderResponse,
         onDismissCallback: @escaping (PaymentResponse?) -> Void,
         onAuthorizeApplePayCallback: @escaping OnAuthorizeApplePayCallback) {
        self.applePayDelegate = applePayDelegate
        self.order = order
        self.onAuthorizeApplePayCallback = onAuthorizeApplePayCallback
        self.onDismissCallback = onDismissCallback
        super.init()
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelect paymentMethod: PKPaymentMethod,
                                            handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void) {
        if let newPaymentMethod = applePayDelegate.didSelectPaymentMethod?(paymentMethod: paymentMethod) {
            completion(newPaymentMethod)
        } else {
            completion(PKPaymentRequestPaymentMethodUpdate(errors: nil, paymentSummaryItems: []))
        }
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelect shippingMethod: PKShippingMethod,
                                            handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        if let newShippingMethod = applePayDelegate.didSelectShippingMethod?(shippingMethod: shippingMethod) {
            completion(newShippingMethod)
        } else {
            completion(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: []))
        }
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelectShippingContact contact: PKContact,
                                            handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
        if let newShippingContact = applePayDelegate.didSelectShippingContact?(shippingContact: contact) {
            completion(newShippingContact)
        } else {
            completion(PKPaymentRequestShippingContactUpdate(errors: nil,
            paymentSummaryItems: [],
            shippingMethods: []))
        }
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // The user has approved the sheet (Face/Touch ID). Everything after this point is
        // the SDK's own work, so this line is the boundary between "Apple Pay failed" and
        // "we failed after Apple Pay succeeded".
        NISdkLogger.event("""
                          applePay — user authorized the sheet; \
                          network: \(payment.token.paymentMethod.network?.rawValue ?? "nil"), \
                          paymentData: \(payment.token.paymentData.count) bytes. Posting to the gateway…
                          """,
                          log: NISdkLogger.payment, type: .info)
        self.onAuthorizeApplePayCallback(payment, {
            authorizationResult, paymentResponse in
            NISdkLogger.event("""
                              applePay — sheet result: \(ApplePayController.describe(authorizationResult.status)), \
                              orderState: \(paymentResponse?.state ?? "no payment response")
                              """,
                              log: NISdkLogger.payment,
                              type: authorizationResult.status == .success ? .info : .error)
            DispatchQueue.main.async {
                completion(authorizationResult)
                controller.dismiss(animated: false, completion: {
                    [weak self] in
                    self?.onDismissCallback(paymentResponse)
                })
            }
        })
    }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        // PassKit calls this both when the user dismisses the sheet without authorizing
        // and after an authorized payment finishes.
        NISdkLogger.event("applePay — sheet dismissed (paymentAuthorizationViewControllerDidFinish)",
                          log: NISdkLogger.payment, type: .info)
        controller.dismiss(animated: false, completion: {
            [weak self] in
            self?.onDismissCallback(nil)
        })
    }

    private static func describe(_ status: PKPaymentAuthorizationStatus) -> String {
        switch status {
        case .success: return "success"
        case .failure: return "failure"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }
}
