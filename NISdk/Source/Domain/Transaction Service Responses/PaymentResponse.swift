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
    public let authResponse: AuthResponse?
    public let paymentMethod: PaymentMethod?
    
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
        case authResponse
        case paymentMethod
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
        authResponse = try paymentResponseContainer.decodeIfPresent(AuthResponse.self, forKey: .authResponse)
        paymentMethod = try paymentResponseContainer.decodeIfPresent(PaymentMethod.self, forKey: .paymentMethod)
    }
}

extension PaymentResponse {
    internal func toPartialAuthArgs(accessToken: String?) throws -> PartialAuthArgs {
        guard let partialAmount = authResponse?.partialAmount else {
            throw NSError(domain: "argument partialAmount missing", code: 99)
        }
        
        guard let amount = authResponse?.amount else {
            throw NSError(domain: "argument amount missing", code: 99)
        }
        
        guard let currency = self.amount?.currencyCode else {
            throw NSError(domain: "argument currency missing", code: 99)
        }
        
        guard let acceptUrl = paymentLinks?.partialAuthAccept else {
            throw NSError(domain: "argument partial Auth acceptUrl missing", code: 99)
        }
        
        guard let declineUrl = paymentLinks?.partialAuthDecline else {
            throw NSError(domain: "argument partial Auth declineUrl missing", code: 99)
        }
        
        guard let token = accessToken else {
            throw NSError(domain: "payment token missing", code: 99)
        }
        
        return PartialAuthArgs(
            partialAmount: partialAmount,
            amount: amount,
            currency: currency,
            acceptUrl: acceptUrl,
            declineUrl: declineUrl,
            issuingOrg: paymentMethod?.issuingOrg,
            accessToken: token
        )
    }
}
