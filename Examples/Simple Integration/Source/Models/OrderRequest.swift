//
//  OrderRequest.swift
//  Simple Integration
//
//  Created by Johnny Peter on 23/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import NISdk

// This is just a sample order request class
// Check docs for all possible fields available
struct OrderRequest: Encodable {
    let action: String
    let amount: OrderAmount
    let language: String
    let merchantAttributes: [String: String]?
    var savedCard: SavedCard?
    var type: String?
    var frequency: String?
    var installmentDetails: InstallmentDetails?
    var recurringDetails: RecurringDetails?
    var planReference: String?
    var transactionType: String?
    var tenure: Int?
    var total: OrderAmount?
    var orderStartDate: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var paymentAttempts: Int?
    var invoiceExpiryDate: String?
    var skipInvoiceCreatedEmailNotification: Bool?
    var notifyPayByLink: Bool?
    var paymentStructure: String?
    var initialInstallmentAmount: Double?
    var initialPeriodLength: Int?
    var trialOfferTenure: Int?
    var trialOfferAmount: OrderAmount?
    
    
    private enum OrderRequestCodingKeys: String, CodingKey {
        case action
        case amount
        case language
        case merchantAttributes
        case savedCard
        case type
        case frequency
        case installmentDetails
        case recurringDetails
        case planReference
        case tenure
        case total
        case orderStartDate
        case firstName
        case lastName
        case email
        case transactionType
        case paymentAttempts
        case invoiceExpiryDate
        case skipInvoiceCreatedEmailNotification
        case notifyPayByLink
        case paymentStructure
        case initialInstallmentAmount
        case initialPeriodLength
        case trailOfferTenure
        case trialOfferAmount
    }
}
