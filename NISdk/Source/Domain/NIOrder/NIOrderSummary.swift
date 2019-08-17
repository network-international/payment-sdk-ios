//
//  NIOrderSummary.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct NIOrderSummary {
    public let total: NIAmount
}

extension NIOrderSummary: Codable {
    
    private enum  NIOrderSummaryCodingKeys: String, CodingKey {
        case total
    }
    
    public init(from decoder: Decoder) throws {
        let NIOrderSummaryContainer = try decoder.container(keyedBy: NIOrderSummaryCodingKeys.self)
        total = try NIOrderSummaryContainer.decode(NIAmount.self, forKey: .total)
    }
}
