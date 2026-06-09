//
//  MerchantDetails.swift
//  NISdk
//
//  Created on 06/03/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation

/// Decoded from `merchantDetails` on the order response. The `reference` field is the
/// gateway-side merchant identifier — used by the SDK to resolve Click-to-Pay DPA
/// credentials from `/config/merchants/{reference}/configs/vctp`.
@objc public class MerchantDetails: NSObject, Codable {
    public var reference: String?
    public var name: String?
    public var companyUrl: String?
    public var email: String?
    public var mobile: String?

    private enum CodingKeys: String, CodingKey {
        case reference
        case name
        case companyUrl
        case email
        case mobile
    }

    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        reference = try c.decodeIfPresent(String.self, forKey: .reference)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        companyUrl = try c.decodeIfPresent(String.self, forKey: .companyUrl)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        mobile = try c.decodeIfPresent(String.self, forKey: .mobile)
    }
}
