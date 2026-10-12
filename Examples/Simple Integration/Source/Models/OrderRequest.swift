//
//  OrderRequest.swift
//  Simple Integration
//
//  Created by Johnny Peter on 23/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

// This is just a sample order request class
// Check docs for all possible fields available
struct OrderRequest: Encodable {
    let action: String
    let amount: OrderAmount
    let language: String
    let merchantAttributes: [String: String]?
    /// Required by outlets with TAF (Click to Pay / passkey) enabled: the gateway
    /// rejects the order with `tafMissingField` unless an email or phone number is
    /// present. It was declared here but left out of the coding keys below, so
    /// Swift's synthesised encoder never wrote it and those outlets returned 422
    /// while Android — which does send it — worked on the same outlet.
    let emailAddress: String = "info@network.global"
    var type: String?
    var frequency: String?
    var installmentDetails: InstallmentDetails?
    var recurringDetails: RecurringDetails?
    
    private enum  OrderRequestCodingKeys: String, CodingKey {
        case action
        case amount
        case language
        case merchantAttributes
        case emailAddress
        case type
        case frequency
        case installmentDetails
        case recurringDetails
    }
}
