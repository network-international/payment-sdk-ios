//
//  Order.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc public class Order: NSObject, Decodable {
    public var type: String?
    public var action: String?
    public var amount: Amount?
    public var formattedAmount: String?
    public var language: String?
    public var merchantAttributes: [String:String]?
    public var emailAddress: String?
    public var reference: String?
    public var outletId: String?
    public var createDateTime: String?
    public var referrer: String?
    public var orderSummary: OrderSummary?
    public var formattedOrderSummary: FormattedOrderSummary?
    public var billingAddress: BillingAddress?
    public var orderLinks: OrderLinks?
    public var paymentMethods: PaymentMethods?
    
    public enum OrderCodingKeys: String, CodingKey {
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
        case orderLinks = "_links"
    }
    
    public func getAuthCode() -> String? {
        if let payPageLink = orderLinks?.payPageLink,
            let url = URLComponents(string: payPageLink) {
            return url.queryItems?.first(where: { $0.name == "code" })?.value
        }
        return nil
    }
    
    public required init(from decoder: Decoder) throws {
        let OrderContainer = try decoder.container(keyedBy: OrderCodingKeys.self)

        type = try OrderContainer.decode(String.self, forKey: .type)
        action = try OrderContainer.decode(String.self, forKey: .action)
        amount = try OrderContainer.decodeIfPresent(Amount.self, forKey: .amount)
        formattedAmount = try OrderContainer.decodeIfPresent(String.self, forKey: .formattedAmount)
        language = try OrderContainer.decodeIfPresent(String.self, forKey: .language)
        merchantAttributes = try OrderContainer.decodeIfPresent([String:String].self, forKey: .merchantAttributes)
        emailAddress = try OrderContainer.decodeIfPresent(String.self, forKey: .emailAddress)
        reference = try OrderContainer.decodeIfPresent(String.self, forKey: .reference)
        outletId = try OrderContainer.decodeIfPresent(String.self, forKey: .outletId)
        createDateTime = try OrderContainer.decodeIfPresent(String.self, forKey: .createDateTime)
        referrer = try OrderContainer.decodeIfPresent(String.self, forKey: .referrer)
        orderSummary = try OrderContainer.decodeIfPresent(OrderSummary.self, forKey: .orderSummary)
        formattedOrderSummary = try OrderContainer.decodeIfPresent(FormattedOrderSummary.self, forKey: .formattedOrderSummary)
        billingAddress = try OrderContainer.decodeIfPresent(BillingAddress.self, forKey: .billingAddress)
        orderLinks = try OrderContainer.decodeIfPresent(OrderLinks.self, forKey:.orderLinks)
    }
}
