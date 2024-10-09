//
//  AaniPayArgs.swift
//  NISdk
//
//  Created by Gautam Chibde on 07/08/24.
//

import Foundation

class AaniPayArgs {
    let amount: Double
    let anniPaymentLink: String
    let currencyCode: String
    let authUrl: String
    let payPageUrl: String
    let backLink: String
    let authCode: String
    
    init(amount: Double,
         anniPaymentLink: String,
         currencyCode: String,
         authUrl: String,
         payPageUrl: String,
         backLink: String,
         authCode: String
    ) {
        self.amount = amount
        self.anniPaymentLink = anniPaymentLink
        self.currencyCode = currencyCode
        self.authUrl = authUrl
        self.payPageUrl = payPageUrl
        self.backLink = backLink
        self.authCode = authCode
    }
}

extension OrderResponse {
    func toAaniPayArgs(_ backLink: String) throws -> AaniPayArgs  {
    guard let payment = embeddedData?.payment?.first else {
            throw NSError(domain: "argument payments missing", code: 99)
        }
        guard let aaniPayLink = payment.paymentLinks?.aaniPaymentLink else {
            throw NSError(domain: "argument aaniPayLink missing", code: 99)
        }
        
        guard let amount = self.amount?.value else {
            throw NSError(domain: "argument amount missing", code: 99)
        }
        
        guard let currencyCode = self.amount?.currencyCode else {
            throw NSError(domain: "argument currencyCode missing", code: 99)
        }
        
        guard let authUrl = orderLinks?.paymentAuthorizationLink else {
            throw NSError(domain: "argument authUrl missing", code: 99)
        }
        
        guard let payPageUrl = orderLinks?.payPageLink else {
            throw NSError(domain: "argument payPageUrl missing", code: 99)
        }
        
        guard let authCode = getAuthCode() else {
            throw NSError(domain: "argument auth code missing", code: 99)
        }
        
        return AaniPayArgs(
            amount: amount,
            anniPaymentLink: aaniPayLink,
            currencyCode: currencyCode,
            authUrl: authUrl,
            payPageUrl: payPageUrl,
            backLink: backLink,
            authCode: authCode
        )
    }
}
