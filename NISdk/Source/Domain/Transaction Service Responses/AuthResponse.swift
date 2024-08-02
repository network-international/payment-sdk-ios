//
//  AuthResponse.swift
//  NISdk
//
//  Created by Gautam Chibde on 12/07/24.
//

import Foundation

public class AuthResponse: NSObject, Codable {
    let amount: Double?
    let partialAmount: Double?
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.amount = try container.decodeIfPresent(Double.self, forKey: .amount)
        self.partialAmount = try container.decodeIfPresent(Double.self, forKey: .partialAmount)
    }
}
