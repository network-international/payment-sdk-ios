//
//  NIPaymentError.swift
//  NISdk
//

import Foundation

/// Why a payment did not succeed.
///
/// `PaymentStatus` says *that* a payment failed; this says *why*, which a merchant needs in order to
/// react sensibly — a network drop is worth retrying, a decline is not, and a configuration problem
/// is the integrator's to fix rather than the payer's.
@objc public enum NIPaymentErrorCategory: Int, RawRepresentable {
    /// The request could not be made or its response could not be read — offline, timed out
    /// in transport, or an unreadable body.
    case network
    /// The order or the SDK integration cannot support this payment: a missing link, an
    /// unsupported action or currency, or absent credentials. Retrying will not help.
    case configuration
    /// The payment provider or gateway rejected the payment on its merits.
    case declined
    /// The payment did not reach a final state in the time allowed. Its true outcome is unknown
    /// and must be confirmed from the order rather than assumed to have failed.
    case timeout
    /// The provider's own flow failed — its hosted page would not load, or it returned a result
    /// that could not be interpreted.
    case provider
    case unknown

    public var rawVal: String {
        switch self {
        case .network: return "network"
        case .configuration: return "configuration"
        case .declined: return "declined"
        case .timeout: return "timeout"
        case .provider: return "provider"
        case .unknown: return "unknown"
        }
    }

    public init?(rawVal: String) {
        switch rawVal {
        case "network": self = .network
        case "configuration": self = .configuration
        case "declined": self = .declined
        case "timeout": self = .timeout
        case "provider": self = .provider
        default: self = .unknown
        }
    }
}

/// Detail accompanying a non-successful payment, delivered through the optional
/// `paymentDidComplete(with:error:)` delegate method.
@objc public class NIPaymentError: NSObject {
    @objc public let category: NIPaymentErrorCategory
    /// Human-readable detail, usually the gateway's own message. For logs and diagnostics — not
    /// intended to be shown to payers verbatim.
    @objc public let message: String?
    /// The payment method the failure came from, e.g. `BENEFIT`.
    @objc public let paymentMethod: String?

    @objc public init(category: NIPaymentErrorCategory, message: String?, paymentMethod: String? = nil) {
        self.category = category
        self.message = message
        self.paymentMethod = paymentMethod
    }

    public override var description: String {
        "NIPaymentError(category: \(category.rawVal), method: \(paymentMethod ?? "-"), message: \(message ?? "-"))"
    }
}
