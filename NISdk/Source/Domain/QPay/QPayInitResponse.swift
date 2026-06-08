//
//  QPayInitResponse.swift
//  NISdk
//

import Foundation

struct QPayInitResponse: Decodable {
    let redirectUri: String?
    let cancelled: Bool?

    let amount: String?
    let currencyCode: String?
    let pun: String?
    let merchantModuleSessionID: String?
    let paymentDescription: String?
    let nationalID: String?
    let merchantID: String?
    let bankID: String?
    let lang: String?
    let action: String?
    let secureHash: String?
    let transactionRequestDate: String?
    let extraFieldsF14: String?
    let quantity: String?

    private enum CodingKeys: String, CodingKey {
        case redirectUri
        case cancelled
        case amount = "Amount"
        case currencyCode = "CurrencyCode"
        case pun = "PUN"
        case merchantModuleSessionID = "MerchantModuleSessionID"
        case paymentDescription = "PaymentDescription"
        case nationalID = "NationalID"
        case merchantID = "MerchantID"
        case bankID = "BankID"
        case lang = "Lang"
        case action = "Action"
        case secureHash = "SecureHash"
        case transactionRequestDate = "TransactionRequestDate"
        case extraFieldsF14 = "ExtraFields_f14"
        case quantity = "Quantity"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        redirectUri = try c.decodeIfPresent(String.self, forKey: .redirectUri)
        cancelled = try c.decodeIfPresent(Bool.self, forKey: .cancelled)
        amount = QPayInitResponse.decodeStringy(c, .amount)
        currencyCode = QPayInitResponse.decodeStringy(c, .currencyCode)
        pun = QPayInitResponse.decodeStringy(c, .pun)
        merchantModuleSessionID = QPayInitResponse.decodeStringy(c, .merchantModuleSessionID)
        paymentDescription = QPayInitResponse.decodeStringy(c, .paymentDescription)
        nationalID = QPayInitResponse.decodeStringy(c, .nationalID)
        merchantID = QPayInitResponse.decodeStringy(c, .merchantID)
        bankID = QPayInitResponse.decodeStringy(c, .bankID)
        lang = QPayInitResponse.decodeStringy(c, .lang)
        action = QPayInitResponse.decodeStringy(c, .action)
        secureHash = QPayInitResponse.decodeStringy(c, .secureHash)
        transactionRequestDate = QPayInitResponse.decodeStringy(c, .transactionRequestDate)
        extraFieldsF14 = QPayInitResponse.decodeStringy(c, .extraFieldsF14)
        quantity = QPayInitResponse.decodeStringy(c, .quantity)
    }

    /// QCB gateway returns numeric or string values for the same fields (e.g. `"Amount": 500` vs `"500"`).
    /// `try?` swallows type-mismatch throws so we fall through to the next type cleanly.
    private static func decodeStringy(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
        if let s = try? c.decodeIfPresent(String.self, forKey: key), let s = s { return s }
        if let i = try? c.decode(Int.self, forKey: key) { return String(i) }
        if let d = try? c.decode(Double.self, forKey: key) { return String(d) }
        return nil
    }
}

extension QPayInitResponse {
    /// Ordered hidden-input set the QCB gateway expects on the redirect POST.
    /// Mirrors `QPayJspResponseKeys` in PayPageV2's `qpayRedirectForm.ts`.
    var orderedFormFields: [(name: String, value: String)] {
        return [
            ("Amount", amount ?? ""),
            ("CurrencyCode", currencyCode ?? ""),
            ("PUN", pun ?? ""),
            ("MerchantModuleSessionID", merchantModuleSessionID ?? ""),
            ("PaymentDescription", paymentDescription ?? ""),
            ("NationalID", nationalID ?? ""),
            ("MerchantID", merchantID ?? ""),
            ("BankID", bankID ?? ""),
            ("Lang", lang ?? ""),
            ("Action", action ?? ""),
            ("SecureHash", secureHash ?? ""),
            ("TransactionRequestDate", transactionRequestDate ?? ""),
            ("ExtraFields_f14", extraFieldsF14 ?? ""),
            ("Quantity", quantity ?? ""),
        ]
    }
}
