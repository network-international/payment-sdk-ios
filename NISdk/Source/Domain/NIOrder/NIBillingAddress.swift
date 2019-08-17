//
//  NIBillingAddress.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct NIBillingAddress: Codable {
    let firstName: String
    let lastName: String
    let address1: String
    let city: String
    let countryCode: String
    
    private enum  NIBillingAddressCodingKeys: String, CodingKey {
        case firstName
        case lastName
        case address1
        case city
        case countryCode
    }
    
    public init(from decoder: Decoder) throws {
        let NIBillingAddressContainer = try decoder.container(keyedBy: NIBillingAddressCodingKeys.self)
        firstName = try NIBillingAddressContainer.decode(String.self, forKey: .firstName)
        lastName = try NIBillingAddressContainer.decode(String.self, forKey: .lastName)
        address1 = try NIBillingAddressContainer.decode(String.self, forKey: .address1)
        city = try NIBillingAddressContainer.decode(String.self, forKey: .city)
        countryCode = try NIBillingAddressContainer.decode(String.self, forKey: .countryCode)
    }
}
