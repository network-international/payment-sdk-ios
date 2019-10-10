//
//  PaymentResponse.swift
//  NISdk
//
//  Created by Johnny Peter on 20/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc public class PaymentResponse: NSObject, Codable {
    public let _id: String?
    public let state: String
    public let amount: Amount?
    public let embeddedData: EmbeddedData?
    public let paymentLinks: PaymentLinks?
    public let threeDSConfig: ThreeDSConfig?
    
    private enum PaymentResponseCodingKeys: String, CodingKey {
        case _id
        case state
        case amount
        case embeddedData = "_embedded"
        case paymentLinks = "_links"
        case threeDSConfig = "3ds"
    }
    
    required public init(from decoder: Decoder) throws {
        let paymentResponseContainer = try decoder.container(keyedBy: PaymentResponseCodingKeys.self)
        _id = try paymentResponseContainer.decodeIfPresent(String.self, forKey: ._id)
        state = try paymentResponseContainer.decodeIfPresent(String.self, forKey: .state) ?? ""
        amount = try paymentResponseContainer.decodeIfPresent(Amount.self, forKey: .amount)
        embeddedData = try paymentResponseContainer.decodeIfPresent(EmbeddedData.self, forKey: .embeddedData)
        paymentLinks = try paymentResponseContainer.decodeIfPresent(PaymentLinks.self, forKey: .paymentLinks)
        threeDSConfig = try paymentResponseContainer.decodeIfPresent(ThreeDSConfig.self, forKey: .threeDSConfig)
    }
}
