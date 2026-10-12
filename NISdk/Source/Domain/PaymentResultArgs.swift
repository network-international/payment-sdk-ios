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
/// installment plan. Amounts are pre-formatted in the payment flow so the result view doesn't
/// have to know about minor units / currency codes; the labels and the month count are left to
/// the view, which localises them.
///
/// The labels and formatting deliberately mirror the offer card on the payment page — the
/// receipt restates the plan the payer just agreed to, so any wording that differs between the
/// two reads as a different plan. The card builds its figures through `from(offer:isIslamic:)`
/// for that reason.
struct SliceReceipt {
    /// The offer's `period` as the gateway sent it, e.g. "4"; the view pluralises it.
    let period: String
    let rate: String               // e.g. "0%"
    let processingFees: String     // e.g. "AED 0.00", or "2%" for a percentage fee type
    /// The issuer's per-installment fee, already added to the amount charged. `nil` when the
    /// offer carried no `commission`, matching the card, which hides the row entirely.
    let installmentFees: String?
    let installmentAmount: String  // e.g. "AED 2,719.50"
    /// `true` when the offer was Islamic (eligibility indicator `"I"`). Drives the
    /// "Profit rate" vs "Interest rate" label, as on the offer card.
    let isIslamic: Bool

    static func from(offer: SliceOffer, isIslamic: Bool) -> SliceReceipt {
        let currency = offer.installmentAmount.currencyCode
        let processingFees = offer.feeType == "P"
            ? "\(offer.fee)%"
            : formatAmount(minorUnits: majorToMinor(Double(offer.fee) ?? 0), currency: currency)
        return SliceReceipt(
            period: offer.period,
            rate: "\(offer.rate)%",
            processingFees: processingFees,
            installmentFees: offer.installmentFeeAmount.map {
                formatAmount(minorUnits: majorToMinor($0), currency: currency)
            },
            installmentAmount: formatAmount(minorUnits: offer.installmentAmount.value, currency: currency),
            isIslamic: isIslamic
        )
    }

    /// Comma-grouped, two decimals, currency code first — the format of every Slice amount on
    /// both the offer card and the receipt.
    static func formatAmount(minorUnits: Int, currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = true
        f.groupingSeparator = ","
        f.groupingSize = 3
        f.decimalSeparator = "."
        let n = f.string(from: NSNumber(value: Double(minorUnits) / 100.0)) ?? "0.00"
        return "\(currency) \(n)"
    }

    /// Rounded, not truncated: `0.29 * 100` is `28.999…` in floating point, so truncating would
    /// quote the payer one fil less than the plan they agreed to.
    private static func majorToMinor(_ major: Double) -> Int {
        Int((major * 100).rounded())
    }
}
