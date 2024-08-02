//
//  PaymentMethod.swift
//  NISdk
//
//  Created by Gautam Chibde on 09/07/24.
//

import Foundation

public class PaymentMethod: NSObject, Codable {
    var issuingOrg: String?
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.issuingOrg = try container.decodeIfPresent(String.self, forKey: .issuingOrg)
    }
}
