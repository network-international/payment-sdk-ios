//
//  ClickToPayConfig.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation

/// Configuration for Click to Pay (Unified Click to Pay) integration.
/// Used by merchants to enable Click to Pay checkout flow.
@objc public class ClickToPayConfig: NSObject {

    /// The DPA (Digital Payment Application) ID assigned by Visa during onboarding.
    public let dpaId: String

    /// The DPA Client ID for multi-merchant setups. Optional.
    public let dpaClientId: String?

    /// Supported card brands (e.g., ["visa", "mastercard"])
    public let cardBrands: [String]

    /// The DPA name shown to consumers during checkout
    public let dpaName: String

    /// Whether to use sandbox environment
    public let isSandbox: Bool

    /// The Key ID (kid) for JWE card encryption. Required for Add Card flow.
    /// Obtained from the /vctp/config backend endpoint.
    public let kid: String?

    /// The public key (X.509 PEM certificate) for JWE card encryption. Required for Add Card flow.
    /// Obtained from the /vctp/config backend endpoint.
    public let publicKey: String?

    static let sandboxSdkUrl = "https://sandbox.secure.checkout.visa.com/checkout-widget/resources/js/integration/v2/sdk.js"
    static let productionSdkUrl = "https://secure.checkout.visa.com/checkout-widget/resources/js/integration/v2/sdk.js"

    @objc public init(dpaId: String,
                      dpaClientId: String? = nil,
                      cardBrands: [String] = ["visa", "mastercard"],
                      dpaName: String,
                      isSandbox: Bool = false,
                      kid: String? = nil,
                      publicKey: String? = nil) {
        self.dpaId = dpaId
        self.dpaClientId = dpaClientId
        self.cardBrands = cardBrands
        self.dpaName = dpaName
        self.isSandbox = isSandbox
        self.kid = kid
        self.publicKey = publicKey
        super.init()
    }

    var sdkUrl: String {
        return isSandbox ? ClickToPayConfig.sandboxSdkUrl : ClickToPayConfig.productionSdkUrl
    }

    var cardBrandsParam: String {
        return cardBrands.joined(separator: ",")
    }
}
