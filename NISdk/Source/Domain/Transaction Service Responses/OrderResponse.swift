//
//  Order.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc public class OrderResponse: NSObject, Codable {
    public var _id: String?
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
    public var paymentMethods: PaymentMethods?
    public var orderLinks: OrderLinks?
    public var embeddedData: EmbeddedData?
    
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
    
    @objc public static func decodeFrom(data: Data) throws -> OrderResponse {
        do {
            let orderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
            return orderResponse
        } catch let error {
            throw error
        }
    }
    
    override required init() {
        super.init()
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
    
    class Builder {
        private var orderResponse = OrderResponse()
        
        func withId(_id: String) -> Builder {
            orderResponse._id = _id
            return self
        }
        
        func withAction(action: String) -> Builder {
            orderResponse.action = action
            return self
        }
        
        func build() -> OrderResponse {
            return orderResponse
        }
        
    }
}
