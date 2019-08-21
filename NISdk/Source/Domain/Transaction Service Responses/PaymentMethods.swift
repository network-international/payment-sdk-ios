//
//  PaymentTypes.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public class PaymentMethods: Codable {
    var card: [CardProviders]?
    var wallet: [WalletProviders]?
    
    public enum CardProviders: String, Codable {
        case visa = "VISA"
        case masterCard = "MASTERCARD"
        case dinersClubInternational = "DINERS_CLUB_INTERNATIONAL"
        case jcb = "JCB"
        case americanExpress = "AMERICAN_EXPRESS"
        case discover = "DISCOVER"
    }
    
    public enum WalletProviders: String, Codable, CaseIterable {
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

        card = try PaymentTypesContainer.decodeIfPresent([CardProviders].self, forKey: .card)
        wallet = try PaymentTypesContainer.decodeIfPresent([WalletProviders].self, forKey: .wallet)
    }
}
