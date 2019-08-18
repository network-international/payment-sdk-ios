//
//  PaymentTypes.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public class PaymentTypes: Codable {
    var card: [CardProviders]
    var wallet: [WalletProviders]
    
    public enum CardProviders: String, Codable {
        case visa
        case masterCard
        case dinersClubInternational
        case jcb
        case americanExpress
    }
    
    public enum WalletProviders: String, Codable {
        case applePay
        case samsungPay
        case chinaUnionPay
    }
    
    private enum PaymentTypesCodingKeys: String, CodingKey {
        case card
        case wallet
    }
    
    required public init(from decoder: Decoder) throws {
        let PaymentTypesContainer = try decoder.container(keyedBy: PaymentTypesCodingKeys.self)

        card = try PaymentTypesContainer.decode([CardProviders].self, forKey: .card)
        wallet = try PaymentTypesContainer.decode([WalletProviders].self, forKey: .wallet)
    }
}
