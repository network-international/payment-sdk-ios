//
//  Order.swift
//  PaymentSDK
//
//  Created by Niraj Chauhan on 2/19/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

struct Order : Codable
{
    let id                  : String
    let amount              : Amount
    let language            : String
    let merchantAttributes  : MerchantAttributes?
    let outletId            : String?
    let createDateTime      : String
    let paymentMethods      : PaymentMethods
    let embedded            : Embedded
    
    struct PaymentMethods : Codable
    {
        let card : [String]? //TODO: add other methods or change it to generic collection
    }
    
    struct MerchantAttributes: Codable
    {
        let redirectUrl : String?
    }
    
    enum CodingKeys: String, CodingKey
    {
        case paymentMethods, language, amount, createDateTime, merchantAttributes, outletId
        case embedded   = "_embedded"
        case id         = "_id"
    }
    
    struct Embedded: Codable
    {
        let payment : [Payment]
        
        struct Payment: Codable
        {
            let state           : String
            let amount          : Amount
            let updateDateTime  : String
            let links           : PaymentLinks
            let id              : String
            
            enum CodingKeys: String, CodingKey
            {
                case state, amount, updateDateTime
                case links  = "_links"
                case id     = "_id"
            }
        }
    }
    
    struct PaymentLinks: Codable
    {
        let card : Link?
        let applePay : Link?
        
        enum CodingKeys: String, CodingKey
        {
            case card = "payment:card"
            case applePay = "payment:apple_pay"
        }
    }
    
    struct Amount : Codable
    {
        let currencyCode    : String
        let value           : Int
        let formattedValue  : String?
    }
}
