//
//  NIPaymentTypes.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public class NIPaymentTypes: Codable {
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
    
    
    private enum NIPaymentTypesCodingKeys: String, CodingKey {
        case card
        case wallet
    }
    
    required public init(from decoder: Decoder) throws {
        let NIPaymentTypesContainer = try decoder.container(keyedBy: NIPaymentTypesCodingKeys.self)

        card = try NIPaymentTypesContainer.decode([CardProviders].self, forKey: .card)
        wallet = try NIPaymentTypesContainer.decode([WalletProviders].self, forKey: .wallet)
    }
}
