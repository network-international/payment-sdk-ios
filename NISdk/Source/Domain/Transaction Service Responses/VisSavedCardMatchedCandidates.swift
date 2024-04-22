//
//  VisSavedCardMatchedCandidates.swift
//  NISdk
//
//  Created by Gautam Chibde on 16/04/24.
//

import Foundation

public struct VisSavedCardMatchedCandidates: Codable {
    public var matchedCandidates: [MatchedCandidate]
    
    public init() {
        self.matchedCandidates = []
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.matchedCandidates = try container.decode([MatchedCandidate].self, forKey: .matchedCandidates)
    }
}
