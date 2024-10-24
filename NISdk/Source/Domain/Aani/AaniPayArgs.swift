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
    let backLink: String
    let accessToken: String
    let payPageUrl: String
    
    init(amount: Double,
         anniPaymentLink: String,
         currencyCode: String,
         backLink: String,
         accessToken: String,
         payPageUrl: String
    ) {
        self.amount = amount
        self.anniPaymentLink = anniPaymentLink
        self.currencyCode = currencyCode
        self.backLink = backLink
        self.accessToken = accessToken
        self.payPageUrl = payPageUrl
    }
}

extension OrderResponse {
    func toAaniPayArgs(_ backLink: String, accessToken: String) -> AaniPayArgs?  {
        guard let payment = embeddedData?.payment?.first else {
            return nil
        }
        guard let aaniPayLink = payment.paymentLinks?.aaniPaymentLink else {
            return nil
        }
        
        guard let amount = self.amount?.value else {
            return nil
        }
        
        guard let currencyCode = self.amount?.currencyCode else {
            return nil
        }
        
        guard let payPageUrl = orderLinks?.payPageLink else {
            return nil
        }
        
        return AaniPayArgs(
            amount: amount,
            anniPaymentLink: aaniPayLink,
            currencyCode: currencyCode,
            backLink: backLink,
            accessToken: accessToken,
            payPageUrl: payPageUrl
        )
    }
}
