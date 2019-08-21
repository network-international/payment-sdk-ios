//
//  PaymentLinks.swift
//  NISdk
//
//  Created by Johnny Peter on 21/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct PaymentLinks {
    public let paymentLink: String?
    public let cardPaymentLink: String?
    public let savedCardPaymentLink: String?
}

extension PaymentLinks: Codable {
    
    private enum OrderLinksCodingKeys: String, CodingKey {
        case paymentLink = "self"
        case cardPaymentLink = "payment:card"
        case savedCardPaymentLink = "payment:saved-card"
    }
    
    private enum hrefCodingKeys: String, CodingKey {
        case href
    }
    
    public init(from decoder: Decoder) throws {
        let paymentLinksContainer = try decoder.container(keyedBy: OrderLinksCodingKeys.self)
        
        let paymentLinkContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .paymentLink)
        paymentLink = try paymentLinkContainer.decodeIfPresent(String.self, forKey: .href)
        
        let cardPaymentLinkContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .cardPaymentLink)
        cardPaymentLink = try cardPaymentLinkContainer.decodeIfPresent(String.self, forKey: .href)
        
        let savedCardPaymentContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .savedCardPaymentLink)
        savedCardPaymentLink = try savedCardPaymentContainer.decodeIfPresent(String.self, forKey: .href)
    }
}
