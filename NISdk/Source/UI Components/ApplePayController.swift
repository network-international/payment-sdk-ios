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
    /// Set by PaymentViewController immediately before presenting, so a dismissal can be
    /// timed. A sheet that closes in well under a second was not closed by a human.
    var sheetPresentedAt: CFAbsoluteTime?
    /// Whether didAuthorizePayment ever fired. If the sheet finishes without it, the user
    /// never approved and nothing was ever sent to the gateway.
    private var didAuthorize = false
    
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
        didAuthorize = true
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
        // and after an authorized payment finishes. Distinguishing the two is the whole
        // question when a payment fails with no gateway call, so say which happened —
        // and how long the sheet was up, since a sheet that closes almost immediately
        // was closed by PassKit, not by a person.
        let visibleFor = sheetPresentedAt.map { CFAbsoluteTimeGetCurrent() - $0 }
        let duration = visibleFor.map { String(format: "%.2fs", $0) } ?? "unknown"
        if didAuthorize {
            NISdkLogger.event("applePay — sheet dismissed after authorization (visible for \(duration))",
                              log: NISdkLogger.payment, type: .info)
        } else {
            NISdkLogger.event("""
                              applePay — sheet dismissed WITHOUT authorization after \(duration). \
                              The user never approved the payment, so nothing was sent to the gateway. \
                              Either the sheet was cancelled, or PassKit closed it because no card in \
                              the Wallet matches the order's supported networks.
                              """,
                              log: NISdkLogger.payment, type: .error)
        }
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
