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
