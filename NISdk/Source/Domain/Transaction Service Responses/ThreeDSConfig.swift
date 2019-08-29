//
//  ThreeDSConfig.swift
//  NISdk
//
//  Created by Johnny Peter on 25/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct ThreeDSConfig: Codable {
    var acsUrl: String?
    var acsPaReq: String?
    var acsMd: String?
    
    private enum ThreeDSConfigCodingKeys: String, CodingKey {
        case acsUrl
        case acsPaReq
        case acsMd
    }
    
    public init(from decoder: Decoder) throws {
        let threeDSConfigContainer = try decoder.container(keyedBy: ThreeDSConfigCodingKeys.self)
        acsUrl = try threeDSConfigContainer.decodeIfPresent(String.self, forKey: .acsUrl)
        acsPaReq = try threeDSConfigContainer.decodeIfPresent(String.self, forKey: .acsPaReq)
        acsMd = try threeDSConfigContainer.decodeIfPresent(String.self, forKey: .acsMd)
    }
}
