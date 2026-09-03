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
    /// Optional installment fee charged by the issuer, as a major-unit amount string
    /// (e.g. "7.00"). Only rendered when present and greater than zero.
    let commission: String?
    let installmentAmount: SliceAmount
    let totalAmount: SliceAmount
}

extension SliceOffer {
    /// Parsed `commission` in major units, non-nil only when the backend sent the flag
    /// with a value greater than zero — the condition for showing the Installment Fee row.
    var installmentFeeAmount: Double? {
        guard let commission = commission,
              let value = Double(commission), value > 0 else { return nil }
        return value
    }
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
