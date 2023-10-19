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
    public let threeDSTwoConfig: ThreeDSTwoConfig?
    public let authenticationCode: String?
    public let orderReference: String?
    public let outletId: String?
    public let savedCard: SavedCard?
    
    public var threeDSMethodNotificationURL: String? {
        get {
            if let uriStr = paymentLinks?.threeDSTwoAuthenticationURL,
               let uri = URL(string: uriStr),
               let host = uri.host {
                return "https://\(host)/api/outlets/\(outletId!)/orders/\(orderReference!)" +
                "/payments/\(_id!)/3ds2/method/notification"
            }
            return nil
        }
    }
    
    public var threeDSMethodData: String? {
        get {
            if let threeDSMethodNotificationURL = threeDSMethodNotificationURL,
               let threeDSServerTransID = threeDSTwoConfig?.threeDSServerTransID {
                let threeDSMethodDataDict:[String: String] =
                ["threeDSMethodNotificationURL": threeDSMethodNotificationURL,
                 "threeDSServerTransID": threeDSServerTransID]
                let jsonData: Data? = try? JSONSerialization.data(withJSONObject: threeDSMethodDataDict)
                let base64Encoded = jsonData?.base64EncodedString()
                return base64Encoded
            }
            return nil
        }
    }
    
    private enum PaymentResponseCodingKeys: String, CodingKey {
        case _id
        case state
        case amount
        case embeddedData = "_embedded"
        case paymentLinks = "_links"
        case threeDSConfig = "3ds"
        case threeDSTwoConfig = "3ds2"
        case authenticationCode = "authenticationCode"
        case orderReference = "orderReference"
        case outletId = "outletId"
        case savedCard
    }
    
    @objc public static func decodeFrom(data: Data) throws -> PaymentResponse {
        do {
            let paymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
            return paymentResponse
        } catch let error {
            throw error
        }
    }
    
    required public init(from decoder: Decoder) throws {
        let paymentResponseContainer = try decoder.container(keyedBy: PaymentResponseCodingKeys.self)
        _id = try paymentResponseContainer.decodeIfPresent(String.self, forKey: ._id)
        state = try paymentResponseContainer.decodeIfPresent(String.self, forKey: .state) ?? ""
        amount = try paymentResponseContainer.decodeIfPresent(Amount.self, forKey: .amount)
        embeddedData = try paymentResponseContainer.decodeIfPresent(EmbeddedData.self, forKey: .embeddedData)
        paymentLinks = try paymentResponseContainer.decodeIfPresent(PaymentLinks.self, forKey: .paymentLinks)
        threeDSConfig = try paymentResponseContainer.decodeIfPresent(ThreeDSConfig.self, forKey: .threeDSConfig)
        threeDSTwoConfig = try paymentResponseContainer.decodeIfPresent(ThreeDSTwoConfig.self, forKey: .threeDSTwoConfig)
        authenticationCode = try paymentResponseContainer.decodeIfPresent(String.self, forKey: .authenticationCode)
        orderReference = try paymentResponseContainer.decodeIfPresent(String.self, forKey: .orderReference)
        outletId = try paymentResponseContainer.decodeIfPresent(String.self, forKey: .outletId)
        savedCard = try paymentResponseContainer.decodeIfPresent(SavedCard.self, forKey: .savedCard)
    }
}
