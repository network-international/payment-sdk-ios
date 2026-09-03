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
    /// True from the moment the user authorizes until the gateway answers. PassKit can call
    /// didFinish inside this window — the user taps Cancel on the spinner, or PassKit closes
    /// the sheet itself — and treating that as a result would report a failure to the
    /// merchant while the real payment response is still in flight.
    private var isAuthorizationInProgress = false
    /// True once a result has been handed to the SDK. A sheet produces exactly one result;
    /// anything after the first is a duplicate and must not reach the merchant.
    private var hasCompletedApplePay = false
    
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
        // A result has already been reported for this sheet, so there is nothing left to
        // post. Complete the handler anyway: returning without calling it leaves PassKit
        // waiting forever on a sheet that can no longer be finished.
        guard !hasCompletedApplePay else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }
        isAuthorizationInProgress = true
        self.onAuthorizeApplePayCallback(payment, {
            authorizationResult, paymentResponse in
            DispatchQueue.main.async {
                // The gateway has answered, so this path owns the outcome. Both flags are
                // set on the main queue, the same queue didFinish is delivered on, so the
                // two callbacks can never observe a half-updated state.
                self.hasCompletedApplePay = true
                self.isAuthorizationInProgress = false
                completion(authorizationResult)
                controller.dismiss(animated: false, completion: {
                    [weak self] in
                    self?.onDismissCallback(paymentResponse)
                })
            }
        })
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        // PassKit calls this at the end of the sheet's life: when the user dismisses it
        // without authorizing, while an authorized payment is still being posted, and after
        // that payment finishes. Only the first of those is this path's to report — once the
        // user has approved, the authorization path owns the outcome, and the `nil` reported
        // here reads as PaymentFailed and would reach the merchant ahead of the real
        // response. The sheet is deliberately left up while the gateway call is in flight;
        // the authorization path dismisses it when the response lands.
        guard !isAuthorizationInProgress, !hasCompletedApplePay else {
            return
        }
        hasCompletedApplePay = true
        controller.dismiss(animated: false, completion: {
            [weak self] in
            self?.onDismissCallback(nil)
        })
    }
}
