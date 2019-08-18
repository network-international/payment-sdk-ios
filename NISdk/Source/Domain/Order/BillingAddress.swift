//
//  BillingAddress.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct BillingAddress: Codable {
    let firstName: String
    let lastName: String
    let address1: String
    let city: String
    let countryCode: String
    
    private enum  BillingAddressCodingKeys: String, CodingKey {
        case firstName
        case lastName
        case address1
        case city
        case countryCode
    }
    
    public init(from decoder: Decoder) throws {
        let BillingAddressContainer = try decoder.container(keyedBy: BillingAddressCodingKeys.self)
        firstName = try BillingAddressContainer.decode(String.self, forKey: .firstName)
        lastName = try BillingAddressContainer.decode(String.self, forKey: .lastName)
        address1 = try BillingAddressContainer.decode(String.self, forKey: .address1)
        city = try BillingAddressContainer.decode(String.self, forKey: .city)
        countryCode = try BillingAddressContainer.decode(String.self, forKey: .countryCode)
    }
}
