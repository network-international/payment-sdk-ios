//
//  BnplProvider.swift
//  NISdk
//

import Foundation

/// The buy-now-pay-later providers the gateway offers as alternative payment methods.
///
/// Tamara and Tabby are the same integration end to end — same request body, same hosted-checkout
/// redirect, same accept-then-poll finish — and differ only in the nouns below. Modelling that as
/// data rather than as two near-identical controllers is what keeps the two flows from drifting
/// apart as either provider changes.
enum BnplProvider: String, CaseIterable, Equatable {
    case tamara
    case tabby

    /// Name in the order's `paymentMethods.apm` array.
    var apmName: String {
        switch self {
        case .tamara: return "TAMARA"
        case .tabby: return "TABBY"
        }
    }

    /// HAL rel carrying the checkout endpoint, e.g. `payment:tamara`.
    var linkRel: String { "payment:\(rawValue)" }

    /// Last path segment of the checkout endpoint, used when the rel is absent and the endpoint has
    /// to be derived from the payment's own `self` href.
    var pathSegment: String { rawValue }

    /// Field name the provider's `/accept` endpoint expects its own identifier under. The gateway
    /// named these itself and they do not follow one convention: Tamara wants the checkout's order
    /// id, Tabby the payment id.
    var acceptIdField: String {
        switch self {
        case .tamara: return "tamaraOrderId"
        case .tabby: return "tabbyPaymentId"
        }
    }

    /// Names the provider on any error handed to the merchant.
    var methodName: String { apmName }

    var titleKey: String {
        switch self {
        case .tamara: return "Pay with Tamara"
        case .tabby: return "Pay with Tabby"
        }
    }

    /// Title of the hosted-checkout screen.
    var displayNameKey: String {
        switch self {
        case .tamara: return "Tamara"
        case .tabby: return "Tabby"
        }
    }

    /// Optional brand mark. Hosts that ship the asset get it on the row; the row stays text-only
    /// otherwise rather than falling back to a placeholder.
    var logoAssetName: String {
        switch self {
        case .tamara: return "tamaraLogo"
        case .tabby: return "tabbyLogo"
        }
    }

    /// Height the brand mark is drawn at, in points. Neither provider ships a square badge, so the
    /// 40pt the other payment rows use would run the mark to 200pt wide and crowd the title off the
    /// row. The two differ because Tamara's asset is a bare wordmark while Tabby's is a filled badge
    /// whose lettering occupies about 60% of its height — matched on the size of the letters rather
    /// than of the asset, so the two rows read as equals.
    var logoHeight: CGFloat {
        switch self {
        case .tamara: return 16
        case .tabby: return 26
        }
    }

    var accessibilityIdentifier: String { "sdk_paymentpage_radio_\(rawValue)" }

    /// Identifies the provider on a `UIView.tag`, so a row can say which provider it is to a
    /// selector that cannot take an argument. Offset well clear of 0, which every view has by
    /// default and which would otherwise make an untagged view look like the first provider.
    private static let rowTagBase = 8100

    var rowTag: Int {
        BnplProvider.rowTagBase + (BnplProvider.allCases.firstIndex(of: self) ?? 0)
    }

    init?(rowTag: Int) {
        let index = rowTag - BnplProvider.rowTagBase
        guard BnplProvider.allCases.indices.contains(index) else { return nil }
        self = BnplProvider.allCases[index]
    }

    /// Smallest basket the provider will finance, by currency, in major units. Only the amounts the
    /// hosted paypage enforces are listed: a currency that is absent is left to the gateway, which
    /// rejects the checkout on its own terms. Showing an option that is certain to fail is worse
    /// than not showing it, but guessing a limit the provider never set is worse still.
    var minimumAmounts: [String: Double] {
        switch self {
        case .tabby: return ["AED": 10]
        case .tamara: return [:]
        }
    }
}
