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
    let sliceReceipt: SliceReceipt?

    init(isSuccess: Bool, amount: String?, transactionId: String, dateTime: String,
         cardProviders: [CardProvider], orderItems: [OrderItem] = [],
         sliceReceipt: SliceReceipt? = nil) {
        self.isSuccess = isSuccess
        self.amount = amount
        self.transactionId = transactionId
        self.dateTime = dateTime
        self.cardProviders = cardProviders
        self.orderItems = orderItems
        self.sliceReceipt = sliceReceipt
    }
}

/// Display-ready slice details surfaced on the success screen when the user paid with a Slice
/// installment plan. All fields are pre-formatted in the payment flow so the result view
/// doesn't have to know about minor units / currency codes.
struct SliceReceipt {
    let tenor: String              // e.g. "4 Months"
    let interestRate: String       // e.g. "0%"
    let fees: String               // e.g. "AED 0.00"
    let installmentAmount: String  // e.g. "AED 2,719.50"
    /// `true` when the offer was Islamic (eligibility indicator `"I"`). Drives the
    /// "Murabaha" vs "Interest rate" label on the result screen.
    let isIslamic: Bool
}
