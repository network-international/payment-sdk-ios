//
//  BnplInitResponse.swift
//  NISdk
//

import Foundation

/// Response of `POST .../payments/{paymentRef}/{tamara|tabby}`.
///
/// Observed verbatim from the gateway for Tamara:
/// `{"webUrl": "https://checkout-sandbox.tamara.co/checkout/…", "tamaraOrderId": "761d053b-…"}`
///
/// `webUrl` is the field both providers use and the one the hosted paypage reads. The sibling APMs
/// spell it differently — Benefit returns `paymentUrl`, QPay `redirectUri` — so those spellings are
/// accepted too rather than leaving the payer on a blank sheet if the gateway ever answers in kind.
struct BnplInitResponse: Decodable {
    let webUrl: String?
    let redirectUrl: String?
    let paymentUrl: String?
    let checkoutUrlField: String?
    /// True when the gateway aborted the checkout itself, e.g. the order was already paid.
    let cancelled: Bool?
    /// True when the gateway refused the checkout while still answering 200 — an over-large basket
    /// comes back as `{"isError": true, "errorMessage": "order amount too high"}`. Read explicitly
    /// rather than inferred from a missing URL: the two have only ever coincided by luck, and a
    /// response carrying both would otherwise send the payer to a checkout the gateway rejected.
    let isError: Bool?
    let errorMessage: String?
    /// The provider's own identifier for this checkout, returned at initiation. It is what the
    /// `/accept` call needs, so capturing it here means a return leg that arrives without it in the
    /// query string can still be finalised.
    let providerReference: String?

    private enum CodingKeys: String, CodingKey {
        case webUrl
        case redirectUrl
        case paymentUrl
        case checkoutUrlField = "checkoutUrl"
        case cancelled
        case isError
        case errorMessage
        case tamaraOrderId
        case tabbyPaymentId
        case orderId
        case paymentId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        webUrl = try container.decodeIfPresent(String.self, forKey: .webUrl)
        redirectUrl = try container.decodeIfPresent(String.self, forKey: .redirectUrl)
        paymentUrl = try container.decodeIfPresent(String.self, forKey: .paymentUrl)
        checkoutUrlField = try container.decodeIfPresent(String.self, forKey: .checkoutUrlField)
        cancelled = try container.decodeIfPresent(Bool.self, forKey: .cancelled)
        isError = try container.decodeIfPresent(Bool.self, forKey: .isError)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)

        // Provider-specific names first, then the generic ones — an order id and a payment id are
        // different things, and taking the wrong one would fail the accept call.
        let candidates: [String?] = [
            try container.decodeIfPresent(String.self, forKey: .tamaraOrderId),
            try container.decodeIfPresent(String.self, forKey: .tabbyPaymentId),
            try container.decodeIfPresent(String.self, forKey: .orderId),
            try container.decodeIfPresent(String.self, forKey: .paymentId)
        ]
        providerReference = candidates.compactMap { $0 }.first { !$0.isEmpty }
    }

    /// The hosted page to load, or nil when there is none or the gateway flagged an error.
    var checkoutUrl: String? {
        if isError == true { return nil }
        return [webUrl, redirectUrl, paymentUrl, checkoutUrlField]
            .compactMap { $0 }
            .first { !$0.isEmpty }
    }
}
