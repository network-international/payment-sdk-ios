//
//  Amount.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct Amount: Codable {
    public let currencyCode: String?
    public let value: Int?
    
    private enum AmountCodingKeys: String, CodingKey {
        case currencyCode
        case value
    }
    
    func getFormattedAmount() -> String {
        var orderAmountValue = ""
        if let value = value {
            orderAmountValue = String(value > 0 ? Double(value) / 100 : 0.0);
        }
        return "\(orderAmountValue) \(currencyCode ?? "")"
    }
    
    public init(from decoder: Decoder) throws {
        let AmountContainer = try decoder.container(keyedBy: AmountCodingKeys.self)
        currencyCode = try AmountContainer.decodeIfPresent(String.self, forKey: .currencyCode)
        value = try AmountContainer.decodeIfPresent(Int.self, forKey: .value)
    }
}
