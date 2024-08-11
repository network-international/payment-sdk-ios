//
//  AaniPoolingResponse.swift
//  NISdk
//
//  Created by Gautam Chibde on 07/08/24.
//

import Foundation

class AaniPoolingResponse: NSObject, Codable {
    let state: String
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.state = try container.decode(String.self, forKey: .state)
    }
}
