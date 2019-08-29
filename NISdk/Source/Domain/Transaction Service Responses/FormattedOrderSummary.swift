//
//  FormattedOrderSummary.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct FormattedOrderSummary {
    public let total: String?
}

extension FormattedOrderSummary: Codable {
    
    private enum FormattedOrderSummaryCodingKeys: String, CodingKey {
        case total
    }
    
    public init(from decoder: Decoder) throws {
        let FormattedOrderSummaryContainer = try decoder.container(keyedBy: FormattedOrderSummaryCodingKeys.self)
        total = try FormattedOrderSummaryContainer.decodeIfPresent(String.self, forKey: .total)
    }
}
