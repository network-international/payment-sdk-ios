//
//  PartialAuthArgs.swift
//  NISdk
//
//  Created by Gautam Chibde on 09/07/24.
//

import Foundation

class PartialAuthArgs {
    let partialAmount: Double
    let amount: Double
    let currency: String
    let acceptUrl: String
    let declineUrl: String
    let issuingOrg: String?
    let accessToken: String
    
    init(partialAmount: Double,
         amount: Double,
         currency: String,
         acceptUrl: String,
         declineUrl: String,
         issuingOrg: String?,
         accessToken: String
    ) {
        self.partialAmount = partialAmount
        self.amount = amount
        self.currency = currency
        self.acceptUrl = acceptUrl
        self.declineUrl = declineUrl
        self.issuingOrg = issuingOrg
        self.accessToken = accessToken
    }
    
    func getPartialAmountFormatted() -> String {
        return Amount(currencyCode: currency, value: partialAmount).getFormattedAmount2Decimal()
    }
    
    func getAmountFormatted() -> String {
        return Amount(currencyCode: currency, value: amount).getFormattedAmount2Decimal()
    }
}
