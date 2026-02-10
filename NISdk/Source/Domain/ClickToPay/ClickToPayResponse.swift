//
//  ClickToPayResponse.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation

/// Digital card data (card art) returned from Click to Pay
struct ClickToPayDigitalCardData: Codable {
    let descriptorName: String?
    let artUri: String?
    let artHeight: Int?
    let artWidth: Int?
}

/// Digital card information returned from Click to Pay
struct ClickToPayCard: Codable {
    let srcDigitalCardId: String
    let panLastFour: String?
    let digitalCardData: ClickToPayDigitalCardData?
    let panExpirationMonth: String?
    let panExpirationYear: String?
    let paymentCardDescriptor: String?
    let paymentCardType: String?
    let paymentCardNetwork: String?
}

/// Validation channel for OTP delivery
struct ClickToPayValidationChannel: Codable {
    let id: String
    let type: String
    let maskedValue: String?
}

/// Checkout response from the Visa SDK JS bridge
struct ClickToPayCheckoutResult: Codable {
    let checkoutResponse: String
    let srcDigitalCardId: String?
    let idToken: String?
}

/// Error from the JS bridge
struct ClickToPayJsError: Codable {
    let reason: String
    let message: String
}

/// Result of submitting the Click to Pay payment to the gateway
enum ClickToPayPaymentResult {
    case authorised
    case purchased
    case captured
    case postAuthReview
    case pending
    case requires3DS(paymentResponse: PaymentResponse)
    case failed(String)
}
