//
//  NIAmount.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct NIAmount: Codable {
    public let currencyCode: String?
    public let value: Int?
    
    private enum  NIAmountCodingKeys: String, CodingKey {
        case currencyCode
        case value
    }
    
    public init(from decoder: Decoder) throws {
        let NIAmountContainer = try decoder.container(keyedBy: NIAmountCodingKeys.self)
        currencyCode = try NIAmountContainer.decode(String.self, forKey: .currencyCode)
        value = try NIAmountContainer.decode(Int.self, forKey: .value)
    }
}
