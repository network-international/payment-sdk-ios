//
//  OrderAmount.swift
//  Simple Integration
//
//  Created by Johnny Peter on 23/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

struct OrderAmount: Encodable {
    let currencyCode: String?
    let value: Double?
    
    private enum AmountCodingKeys: String, CodingKey {
        case currencyCode
        case value
    }
}
