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
    case masterCard = "MASTERCARD"
    case dinersClubInternational = "DINERS_CLUB_INTERNATIONAL"
    case jcb = "JCB"
    case americanExpress = "AMERICAN_EXPRESS"
    case discover = "DISCOVER"
    case jaywan = "JAYWAN"
    case mada = "MADA"
    case visa = "VISA"
    case qpay = "QPAY"
    case benefit = "BENEFIT"
    case unknown

    /// QPAY and BENEFIT are gateway routing schemes that the gateway reports inside
    /// `paymentMethods.card`, not card networks Apple Pay can tokenize. Excluding them keeps them
    /// out of `PKPaymentRequest.supportedNetworks`, which would otherwise advertise Visa on an
    /// outlet that never enabled Visa.
    public var isApplePayNetwork: Bool {
        switch self {
        case .qpay, .benefit: return false
        default: return true
        }
    }

    public var pkNetworkType: PKPaymentNetwork {
        switch self {
        case .visa: return .visa
        case .masterCard: return .masterCard
        case .americanExpress: return .amex
        case .dinersClubInternational: return .masterCard
        case .discover: return .discover
        case .jcb: return .JCB
        case .mada: if #available(iOS 12.1.1, *) {
            return .mada
        } else {
            return .visa
        }
        case .jaywan: return .visa
        case .qpay: return .visa
        case .benefit: return .visa
        case .unknown: return .visa
        }
    }
}
