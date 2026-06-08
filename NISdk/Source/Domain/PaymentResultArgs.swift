//
//  PaymentResultArgs.swift
//  NISdk
//

import Foundation

struct PaymentResultArgs {
    let isSuccess: Bool
    let amount: String?
    let transactionId: String
    let dateTime: String
    let cardProviders: [CardProvider]
    let orderItems: [OrderItem]

    init(isSuccess: Bool, amount: String?, transactionId: String, dateTime: String,
         cardProviders: [CardProvider], orderItems: [OrderItem] = []) {
        self.isSuccess = isSuccess
        self.amount = amount
        self.transactionId = transactionId
        self.dateTime = dateTime
        self.cardProviders = cardProviders
        self.orderItems = orderItems
    }
}
