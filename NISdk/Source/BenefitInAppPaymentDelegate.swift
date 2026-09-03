//
//  BenefitInAppPaymentDelegate.swift
//  NISdk
//
//  Public surface for the BENEFIT In-App (BenefitPay wallet app-switch) payment method.
//  Unlike the N-Genius hosted "Benefit" flow, this is a standalone wallet launcher: it hands the
//  transaction to the BenefitPay app via the FOO BenefitInAppSDK and receives the result back over
//  the app's URL scheme. It is NOT bound to an N-Genius OrderResponse.
//

import Foundation

@objc public protocol BenefitInAppPaymentDelegate {
    /// Called once BenefitPay returns a result to the app (via the deep-link callback the host
    /// forwards through `NISdk.handleBenefitInAppCallback(url:)`), or immediately on an invalid request.
    @objc func benefitInAppPaymentCompleted(with status: BenefitInAppPaymentStatus,
                                            result: BenefitInAppResult?)
}

@objc public enum BenefitInAppPaymentStatus: Int {
    case success
    case cancelled
    case failed
    case invalidRequest
}

/// The values BenefitPay returns in the deep-link callback (mirrors BPDLPaymentCallBackItem).
@objc public final class BenefitInAppResult: NSObject {
    @objc public let merchantName: String?
    @objc public let cardNumber: String?
    @objc public let currency: String?
    @objc public let currencyCode: String?
    @objc public let amount: String?
    @objc public let message: String?
    @objc public let referenceId: String?

    init(merchantName: String?, cardNumber: String?, currency: String?, currencyCode: String?,
         amount: String?, message: String?, referenceId: String?) {
        self.merchantName = merchantName
        self.cardNumber = cardNumber
        self.currency = currency
        self.currencyCode = currencyCode
        self.amount = amount
        self.message = message
        self.referenceId = referenceId
    }
}
