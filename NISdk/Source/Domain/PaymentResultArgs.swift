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
}
