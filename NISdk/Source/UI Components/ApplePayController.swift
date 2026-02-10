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
        print("ApplePay: didSelectPaymentMethod - \(paymentMethod.displayName ?? "unknown")")
        if let newPaymentMethod = applePayDelegate.didSelectPaymentMethod?(paymentMethod: paymentMethod) {
            completion(newPaymentMethod)
        } else {
            completion(PKPaymentRequestPaymentMethodUpdate(errors: nil, paymentSummaryItems: []))
        }
    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelect shippingMethod: PKShippingMethod,
                                            handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        print("ApplePay: didSelectShippingMethod - \(shippingMethod.identifier ?? "unknown")")
        if let newShippingMethod = applePayDelegate.didSelectShippingMethod?(shippingMethod: shippingMethod) {
            completion(newShippingMethod)
        } else {
            completion(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: []))
        }
    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelectShippingContact contact: PKContact,
                                            handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
        print("ApplePay: didSelectShippingContact")
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
        print("ApplePay: didAuthorizePayment - network: \(payment.token.paymentMethod.network?.rawValue ?? "unknown"), transactionId: \(payment.token.transactionIdentifier)")
        self.onAuthorizeApplePayCallback(payment, {
            authorizationResult, paymentResponse in
            print("ApplePay: authorization callback - status: \(authorizationResult.status.rawValue), paymentResponse state: \(paymentResponse?.state ?? "nil")")
            DispatchQueue.main.async {
                completion(authorizationResult)
                controller.dismiss(animated: false, completion: {
                    [weak self] in
                    print("ApplePay: controller dismissed after authorization, paymentResponse: \(paymentResponse?.state ?? "nil")")
                    self?.onDismissCallback(paymentResponse)
                })
            }
        })
    }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        print("ApplePay: paymentAuthorizationViewControllerDidFinish (user cancelled or sheet dismissed)")
        controller.dismiss(animated: false, completion: {
            [weak self] in
            print("ApplePay: controller dismissed in didFinish, calling onDismissCallback with nil")
            self?.onDismissCallback(nil)
        })
    }
}
