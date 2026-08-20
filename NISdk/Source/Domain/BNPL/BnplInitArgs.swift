//
//  BnplInitArgs.swift
//  NISdk
//

import Foundation

class BnplInitArgs {
    let provider: BnplProvider
    /// Gateway endpoint that starts the checkout and returns the provider's hosted checkout URL.
    let checkoutLink: String
    /// Gateway endpoint that hands the provider's outcome back to the backend once the payer
    /// returns.
    let acceptLink: String
    /// Order self-link, polled for the final payment state once the payer returns.
    let orderLink: String
    /// Where the provider sends the payer when the checkout is approved.
    let successUrl: String
    /// Where the provider sends the payer when they abandon the checkout.
    let cancelUrl: String
    /// Where the provider sends the payer when the checkout is declined or errors.
    let failureUrl: String

    init(provider: BnplProvider,
         checkoutLink: String,
         acceptLink: String,
         orderLink: String,
         successUrl: String,
         cancelUrl: String,
         failureUrl: String) {
        self.provider = provider
        self.checkoutLink = checkoutLink
        self.acceptLink = acceptLink
        self.orderLink = orderLink
        self.successUrl = successUrl
        self.cancelUrl = cancelUrl
        self.failureUrl = failureUrl
    }

    /// The only product the APM endpoint accepts. Every other value the gateway answers with
    /// `invalidDataFormat` on `type`.
    static let checkoutType = "INSTALLMENTS"
    /// Marks the return legs so the WebView can tell them apart. The providers append their own
    /// parameters to whatever URL they are given, so an extra one of ours rides along untouched.
    static let resultParam = "ni_sdk_result"
}
