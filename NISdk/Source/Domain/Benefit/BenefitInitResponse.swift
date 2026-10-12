//
//  BenefitInitResponse.swift
//  NISdk
//

import Foundation

/// Response of `POST .../payments/{paymentRef}/benefit`. `paymentUrl` is a ready-to-load hosted
/// page; `status` is `Initiated` or `Failed`.
struct BenefitInitResponse: Codable {
    let paymentId: String?
    let paymentUrl: String?
    let status: String?
    let errorMessage: String?

    var isInitiated: Bool {
        status?.caseInsensitiveCompare("Initiated") == .orderedSame
    }
}

/// The gateway's own error envelope, which a rejected initiation answers with instead of a
/// `BenefitInitResponse`. Every field of `BenefitInitResponse` is optional, so that body decodes
/// into an all-nil response and the real reason — "Failed to encrypt BENEFIT trandata" on an outlet
/// whose BENEFIT keys are not provisioned — would otherwise be dropped on the floor.
struct BenefitInitErrorBody: Codable {
    struct Detail: Codable {
        let message: String?
        let errorCode: String?
        let domain: String?
    }

    let message: String?
    let errors: [Detail]?
    let code: Int?

    /// The most specific reason the body carries, qualified by its error code so a support ticket
    /// can name it. Nil when the body is not a gateway error envelope at all.
    var reason: String? {
        if let detail = errors?.first, let text = detail.message, !text.isEmpty {
            guard let code = detail.errorCode, !code.isEmpty else { return text }
            return "\(text) (\(code))"
        }
        guard let message = message, !message.isEmpty else { return nil }
        return message
    }
}
