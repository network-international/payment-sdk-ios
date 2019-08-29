//
//  Order.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc public class OrderResponse: NSObject, Codable {
    public let _id: String
    public let type: String?
    public let action: String?
    public let amount: Amount?
    public let formattedAmount: String?
    public let language: String?
    public let merchantAttributes: [String:String]?
    public let emailAddress: String?
    public let reference: String?
    public let outletId: String?
    public let createDateTime: String?
    public let referrer: String?
    public let orderSummary: OrderSummary?
    public let formattedOrderSummary: FormattedOrderSummary?
    public let billingAddress: BillingAddress?
    public let paymentMethods: PaymentMethods?
    public let orderLinks: OrderLinks?
    public let embeddedData: EmbeddedData?
    
    public enum OrderCodingKeys: String, CodingKey {
        case _id
        case type
        case action
        case amount
        case formattedAmount
        case language
        case merchantAttributes
        case emailAddress
        case reference
        case outletId
        case createDateTime
        case referrer
        case orderSummary
        case formattedOrderSummary
        case billingAddress
        case paymentMethods
        case orderLinks = "_links"
        case embeddedData = "_embedded"
    }
    
    public func getAuthCode() -> String? {
        if let payPageLink = orderLinks?.payPageLink,
            let url = URLComponents(string: payPageLink) {
            return url.queryItems?.first(where: { $0.name == "code" })?.value
        }
        return nil
    }
    
    public required init(from decoder: Decoder) throws {
        let OrderResponseContainer = try decoder.container(keyedBy: OrderCodingKeys.self)

        _id = try OrderResponseContainer.decodeIfPresent(String.self, forKey: ._id) ?? ""
        type = try OrderResponseContainer.decode(String.self, forKey: .type)
        action = try OrderResponseContainer.decode(String.self, forKey: .action)
        amount = try OrderResponseContainer.decodeIfPresent(Amount.self, forKey: .amount)
        formattedAmount = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .formattedAmount)
        language = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .language)
        merchantAttributes = try OrderResponseContainer.decodeIfPresent([String:String].self, forKey: .merchantAttributes)
        emailAddress = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .emailAddress)
        reference = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .reference)
        outletId = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .outletId)
        createDateTime = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .createDateTime)
        referrer = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .referrer)
        orderSummary = try OrderResponseContainer.decodeIfPresent(OrderSummary.self, forKey: .orderSummary)
        formattedOrderSummary = try OrderResponseContainer.decodeIfPresent(FormattedOrderSummary.self, forKey: .formattedOrderSummary)
        billingAddress = try OrderResponseContainer.decodeIfPresent(BillingAddress.self, forKey: .billingAddress)
        paymentMethods = try OrderResponseContainer.decodeIfPresent(PaymentMethods.self, forKey: .paymentMethods)
        orderLinks = try OrderResponseContainer.decodeIfPresent(OrderLinks.self, forKey:.orderLinks)
        embeddedData = try OrderResponseContainer.decodeIfPresent(EmbeddedData.self, forKey: .embeddedData)
    }
}
