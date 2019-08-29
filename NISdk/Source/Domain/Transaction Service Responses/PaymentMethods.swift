//
//  PaymentTypes.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public class PaymentMethods: Codable {
    var card: [CardProvider]?
    var wallet: [WalletProvider]?
    
    public enum PaymentMethodsCodingKeys: String, CodingKey {
        case card
        case wallet
    }
    
    required public init(from decoder: Decoder) throws {
        let paymentTypesContainer = try decoder.container(keyedBy: PaymentMethodsCodingKeys.self)

        card = try paymentTypesContainer.decodeIfPresent([CardProvider].self, forKey: .card)
        wallet = try paymentTypesContainer.decodeIfPresent([WalletProvider].self, forKey: .wallet)
    }
}
