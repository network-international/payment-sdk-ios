//
//  ThreeDSTwoAuthenticationsResponse.swift
//  NISdk
//
//  Created by Johnny Peter on 07/04/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation

class ThreeDSTwoAuthenticationsResponse: NSObject, Codable {
    let threeDSTwo: ThreeDSTwoConfig?
    let state: String?
    
    private enum ThreeDSTwoAuthenticationsResponseCodingKeys: String, CodingKey {
        case threeDSTwo = "3ds2"
        case state = "state"
    }
    
    required public init(from decoder: Decoder) throws {
        let ThreeDSTwoAuthenticationsResponseContainer = try decoder.container(keyedBy: ThreeDSTwoAuthenticationsResponseCodingKeys.self)
        threeDSTwo = try ThreeDSTwoAuthenticationsResponseContainer.decodeIfPresent(ThreeDSTwoConfig.self, forKey: .threeDSTwo)
        state = try ThreeDSTwoAuthenticationsResponseContainer.decodeIfPresent(String.self, forKey: .state)
    }
}
