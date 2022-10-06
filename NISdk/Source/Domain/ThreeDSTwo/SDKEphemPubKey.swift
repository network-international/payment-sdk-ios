//
//  SDKEphemPubKey.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation

class SDKEphemPubKey: NSObject, Codable {
    let kty: String?
    var crv: String?
    var x: String?
    var y: String?
    
    private enum SDKEphemPubKeyCodingKeys: String, CodingKey {
        case kty
        case crv
        case x
        case y
    }
    
    required public init(from decoder: Decoder) throws {
        let paymentResponseContainer = try decoder.container(keyedBy: SDKEphemPubKeyCodingKeys.self)
        kty = try paymentResponseContainer.decodeIfPresent(String.self, forKey: .kty)
        crv = try paymentResponseContainer.decodeIfPresent(String.self, forKey: .crv)
        x = try paymentResponseContainer.decodeIfPresent(String.self, forKey: .x)
        y = try paymentResponseContainer.decodeIfPresent(String.self, forKey: .y)
    }
}
