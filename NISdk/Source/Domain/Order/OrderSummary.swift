//
//  OrderSummary.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct OrderSummary {
    public let total: Amount?
}

extension OrderSummary: Codable {
    
    private enum  OrderSummaryCodingKeys: String, CodingKey {
        case total
    }
    
    public init(from decoder: Decoder) throws {
        let OrderSummaryContainer = try decoder.container(keyedBy: OrderSummaryCodingKeys.self)
        total = try OrderSummaryContainer.decodeIfPresent(Amount.self, forKey: .total)
    }
}
