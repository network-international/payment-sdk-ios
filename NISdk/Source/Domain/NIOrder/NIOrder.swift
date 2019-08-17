//
//  NIOrder.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc public class NIOrder: NSObject, Decodable {
    public var type: String?
    public var action: String?
    public var amount: NIAmount
    public var formattedAmount: String?
    public var language: String?
    public var merchantAttributes: [String:String]
    public var emailAddress: String?
    public var reference: String?
    public var outletId: String?
    public var createDateTime: String?
    public var referrer: String?
    public var orderSummary: NIOrderSummary
    public var formattedOrderSummary: NIFormattedOrderSummary
    public var billingAddress: NIBillingAddress
    
    public enum NIOrderCodingKeys: String, CodingKey {
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
    }
    
    public required init(from decoder: Decoder) throws {
        let NIOrderContainer = try decoder.container(keyedBy: NIOrderCodingKeys.self)

        type = try NIOrderContainer.decode(String.self, forKey: .type)
        action = try NIOrderContainer.decode(String.self, forKey: .action)
        amount = try NIOrderContainer.decode(NIAmount.self, forKey: .amount)
        formattedAmount = try NIOrderContainer.decode(String.self, forKey: .formattedAmount)
        language = try NIOrderContainer.decode(String.self, forKey: .language)
        merchantAttributes = try NIOrderContainer.decode([String:String].self, forKey: .merchantAttributes)
        emailAddress = try NIOrderContainer.decode(String.self, forKey: .emailAddress)
        reference = try NIOrderContainer.decode(String.self, forKey: .reference)
        outletId = try NIOrderContainer.decode(String.self, forKey: .outletId)
        createDateTime = try NIOrderContainer.decode(String.self, forKey: .createDateTime)
        referrer = try NIOrderContainer.decode(String.self, forKey: .referrer)
        orderSummary = try NIOrderContainer.decode(NIOrderSummary.self, forKey: .orderSummary)
        formattedOrderSummary = try NIOrderContainer.decode(NIFormattedOrderSummary.self, forKey: .formattedOrderSummary)
        billingAddress = try NIOrderContainer.decode(NIBillingAddress.self, forKey: .billingAddress)
    }
}
