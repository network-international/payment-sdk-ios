//
//  NIFormattedOrderSummary.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct NIFormattedOrderSummary {
    public let total: String?
}

extension NIFormattedOrderSummary: Codable {
    
    private enum  NIFormattedOrderSummaryCodingKeys: String, CodingKey {
        case total
    }
    
    public init(from decoder: Decoder) throws {
        let NIFormattedOrderSummaryContainer = try decoder.container(keyedBy: NIFormattedOrderSummaryCodingKeys.self)
        total = try NIFormattedOrderSummaryContainer.decode(String.self, forKey: .total)
    }
}
