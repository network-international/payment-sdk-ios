//
//  TestFixtures.swift
//  NISdkTests
//
//  Shared builders for the JSON the gateway actually returns, so each test can
//  start from a realistic order and vary only the field under test.
//

import Foundation
import XCTest
@testable import NISdk

enum TestFixtures {

    /// A minimal-but-complete order payload. `overrides` are merged over the top level,
    /// so a test can swap `action`, `amount` or `paymentMethods` without restating the rest.
    static func orderJSON(
        action: String = "PURCHASE",
        currencyCode: String = "AED",
        value: Double = 5000,
        cardSchemes: [String] = ["VISA", "MASTERCARD"],
        payPageHref: String = "https://paypage.sandbox.ngenius-payments.com/?code=AUTHCODE123",
        paymentLinks: [String: Any]? = nil,
        paymentExtras: [String: Any] = [:],
        overrides: [String: Any] = [:]
    ) -> [String: Any] {
        var payment: [String: Any] = [
            "_id": "urn:payment:pay123",
            "state": "STARTED",
            "reference": "pay-ref-1",
            "_links": paymentLinks ?? defaultPaymentLinks()
        ]
        for (key, value) in paymentExtras { payment[key] = value }

        var json: [String: Any] = [
            "_id": "urn:order:abc123",
            "type": "PURCHASE",
            "action": action,
            "amount": ["currencyCode": currencyCode, "value": value],
            "reference": "ref-123",
            "outletId": "outlet-1",
            "paymentMethods": ["card": cardSchemes, "wallet": ["APPLE_PAY"]],
            "_links": [
                "self": ["href": "https://api.sandbox.ngenius-payments.com/orders/abc123"],
                "payment": ["href": payPageHref],
                "payment-authorization": ["href": "https://api.sandbox.ngenius-payments.com/auth"],
                "cnp:payment-link": ["href": "https://api.sandbox.ngenius-payments.com/payment-link"]
            ],
            "_embedded": ["payment": [payment]]
        ]
        for (key, value) in overrides { json[key] = value }
        return json
    }

    static func defaultPaymentLinks() -> [String: Any] {
        return [
            "self": ["href": "https://api.sandbox.ngenius-payments.com/payments/pay123"],
            "payment:card": ["href": "https://api.sandbox.ngenius-payments.com/payments/pay123/card"],
            "payment:aani": ["href": "https://api.sandbox.ngenius-payments.com/payments/pay123/aani"],
            "payment:aani-qr": ["href": "https://api.sandbox.ngenius-payments.com/payments/pay123/aani-qr"],
            "payment:qpay": ["href": "https://api.sandbox.ngenius-payments.com/payments/pay123/qpay"],
            "payment:slice-eligibility-check": ["href": "https://api.sandbox.ngenius-payments.com/payments/pay123/slice"],
            "payment:visa_click_to_pay": ["href": "https://api.sandbox.ngenius-payments.com/payments/pay123/ctp"]
        ]
    }

    static func data(_ json: [String: Any]) throws -> Data {
        return try JSONSerialization.data(withJSONObject: json, options: [])
    }

    static func order(
        action: String = "PURCHASE",
        currencyCode: String = "AED",
        value: Double = 5000,
        cardSchemes: [String] = ["VISA", "MASTERCARD"],
        payPageHref: String = "https://paypage.sandbox.ngenius-payments.com/?code=AUTHCODE123",
        paymentLinks: [String: Any]? = nil,
        paymentExtras: [String: Any] = [:],
        overrides: [String: Any] = [:]
    ) throws -> OrderResponse {
        let json = orderJSON(action: action,
                             currencyCode: currencyCode,
                             value: value,
                             cardSchemes: cardSchemes,
                             payPageHref: payPageHref,
                             paymentLinks: paymentLinks,
                             paymentExtras: paymentExtras,
                             overrides: overrides)
        return try OrderResponse.decodeFrom(data: try data(json))
    }

    static func decode<T: Decodable>(_ type: T.Type, from json: [String: Any]) throws -> T {
        return try JSONDecoder().decode(type, from: try data(json))
    }
}

extension XCTestCase {
    /// Asserts that `expression` throws, without caring which error — the SDK's argument
    /// mappers all throw opaque `NSError`s, so the identity of the error carries no contract.
    func assertThrows<T>(_ message: String,
                         file: StaticString = #filePath,
                         line: UInt = #line,
                         _ expression: () throws -> T) {
        XCTAssertThrowsError(try expression(), message, file: file, line: line)
    }
}
