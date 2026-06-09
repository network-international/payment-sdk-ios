import Foundation

struct SliceAmount: Codable {
    let currencyCode: String
    let value: Int
}

struct SliceOffer: Codable {
    let period: String
    let rate: String
    let fee: String
    let feeType: String
    let installmentAmount: SliceAmount
    let totalAmount: SliceAmount
}

struct SliceEligibilityResponse: Codable {
    let transactionAmount: SliceAmount
    let offers: [SliceOffer]
    /// Backend flag: "Y" = conventional interest-based offers, "I" = Islamic / Murabaha,
    /// "N" = ineligible (no offers shown). Other values are treated as conventional.
    let indicator: String?
}

struct SliceEligibilityRequest: Codable {
    /// Manual entry: raw card number (digits only). Mutually exclusive with `cardToken`.
    let pan: String?
    /// Saved-card flow: the previously-issued card token. Mutually exclusive with `pan`.
    let cardToken: String?
    let expiry: String

    init(pan: String, expiry: String) {
        self.pan = pan
        self.cardToken = nil
        self.expiry = expiry
    }

    init(cardToken: String, expiry: String) {
        self.pan = nil
        self.cardToken = cardToken
        self.expiry = expiry
    }
}

class SliceRequest: NSObject, Codable {
    let period: String
    let rate: String
    let fee: String

    init(period: String, rate: String, fee: String) {
        self.period = period
        self.rate = rate
        self.fee = fee
    }
}
