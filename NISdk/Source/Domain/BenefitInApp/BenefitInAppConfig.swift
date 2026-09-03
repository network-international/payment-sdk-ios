//
//  BenefitInAppConfig.swift
//  NISdk
//
//  FOO-issued BENEFIT merchant configuration required to start a BenefitPay In-App payment.
//  Every field is provisioned by FOO for a specific BENEFIT merchant; the secretKey HMAC-signs the
//  payload, so it should be delivered at runtime (e.g. from the merchant backend), NOT hard-coded in
//  a shipping build. `callBackTag` MUST match a CFBundleURLScheme registered by the host app.
//

import Foundation

@objc public final class BenefitInAppConfig: NSObject {
    @objc public let appId: String
    @objc public let secretKey: String
    @objc public let amount: String
    @objc public let currencyCode: String        // ISO numeric, e.g. "048" for BHD
    @objc public let merchantId: String
    @objc public let merchantName: String
    @objc public let merchantCity: String
    @objc public let countryCode: String          // ISO alpha-2, e.g. "BH"
    @objc public let merchantCategoryCode: String // ISO 8583 MCC
    @objc public let referenceId: String
    @objc public let callBackTag: String

    @objc public init(appId: String,
                      secretKey: String,
                      amount: String,
                      currencyCode: String,
                      merchantId: String,
                      merchantName: String,
                      merchantCity: String,
                      countryCode: String,
                      merchantCategoryCode: String,
                      referenceId: String,
                      callBackTag: String) {
        self.appId = appId
        self.secretKey = secretKey
        self.amount = amount
        self.currencyCode = currencyCode
        self.merchantId = merchantId
        self.merchantName = merchantName
        self.merchantCity = merchantCity
        self.countryCode = countryCode
        self.merchantCategoryCode = merchantCategoryCode
        self.referenceId = referenceId
        self.callBackTag = callBackTag
    }

    /// True only when none of the mandatory fields are empty. The SDK rejects nil/empty fields.
    var isComplete: Bool {
        return ![appId, secretKey, amount, currencyCode, merchantId, merchantName, merchantCity,
                 countryCode, merchantCategoryCode, referenceId, callBackTag].contains(where: { $0.isEmpty })
    }

    // ==============================================================================================
    // BenefitPay SANDBOX / TEST-WALLET credentials (issued to NETWORK INTERNATIONAL for the EAZY test
    // gateway). For production, replace these with the live FOO-issued values and deliver secretKey
    // at runtime rather than hard-coding it. `callBackTag` must match a CFBundleURLScheme in the host
    // app's Info.plist (here: "tempBN").
    // ==============================================================================================
    @objc public static func benefitPayTest(amount: String = "10",
                                            referenceId: String = "445544") -> BenefitInAppConfig {
        return BenefitInAppConfig(
            appId: "5873774941",
            secretKey: "4n5zcjrwsflvml53l6ny6qww5so65xltd4x6zanlxxxb1",
            amount: amount,
            currencyCode: "048",                 // BHD
            merchantId: "00000001",
            merchantName: "NETWORK INTERNATIONAL",
            merchantCity: "Manama",
            countryCode: "BH",
            merchantCategoryCode: "7399",        // MCC
            referenceId: referenceId,
            callBackTag: "tempBN"
        )
    }
}
