//
//  CardProviders.swift
//  NISdk
//
//  Created by Johnny Peter on 27/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

public enum CardProvider: String, CaseIterable, Codable {
    case visa = "VISA"
    case masterCard = "MASTERCARD"
    case dinersClubInternational = "DINERS_CLUB_INTERNATIONAL"
    case jcb = "JCB"
    case americanExpress = "AMERICAN_EXPRESS"
    case discover = "DISCOVER"
    case unknown
    
    public var pkNetworkType: PKPaymentNetwork {
        switch self {
        case .visa: return .visa
        case .masterCard: return .masterCard
        case .americanExpress: return .amex
        case .dinersClubInternational: return .masterCard
        case .discover: return .discover
        case .jcb: return .JCB
        case .unknown: return .visa
        }
    }
}
