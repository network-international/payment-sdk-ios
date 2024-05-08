//
//  MatchedCandidate.swift
//  NISdk
//
//  Created by Gautam Chibde on 16/04/24.
//

import Foundation

public struct MatchedCandidate: Codable {
    public var cardToken: String?
    public var eligibilityStatus: String?
    
    public init() {
        self.cardToken = nil
        self.eligibilityStatus = nil
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cardToken = try container.decodeIfPresent(String.self, forKey: .cardToken)
        self.eligibilityStatus = try container.decodeIfPresent(String.self, forKey: .eligibilityStatus)
    }
}
