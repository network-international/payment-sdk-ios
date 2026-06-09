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
///
/// Two ways to construct:
///   1. Pass `merchantId` and call `resolve(...)` to fetch `dpaId`/`dpaClientId`/`dpaName`
///      from the gateway's `/config/merchants/{merchantId}/configs/vctp` endpoint.
///   2. (Legacy) Pass `dpaId`/`dpaClientId`/`dpaName` directly if your backend already
///      provides them.
@objc public class ClickToPayConfig: NSObject {

    /// Merchant identifier used to fetch the DPA credentials from the gateway. The SDK can
    /// populate this from `order.merchantDetails.reference` if the merchant doesn't supply
    /// it explicitly; ignored when `dpaId` is already set.
    public internal(set) var merchantId: String?

    /// The DPA (Digital Payment Application) ID. Populated either at init time or via `resolve(...)`.
    public internal(set) var dpaId: String?

    /// The DPA Client ID for multi-merchant setups. Populated either at init time or via `resolve(...)`.
    public internal(set) var dpaClientId: String?

    /// Supported card brands (e.g., ["visa", "mastercard"])
    public let cardBrands: [String]

    /// The DPA name shown to consumers during checkout. Populated either at init time or
    /// via `resolve(...)` from the gateway's `companyPrimaryLegalName`.
    public internal(set) var dpaName: String?

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

    /// Preferred constructor — the merchant supplies only their `merchantId`; the SDK resolves
    /// the DPA credentials via `resolve(...)` before Click to Pay is launched.
    @objc public init(merchantId: String,
                      isSandbox: Bool = false,
                      cardBrands: [String] = ["visa", "mastercard"],
                      kid: String? = nil,
                      publicKey: String? = nil) {
        self.merchantId = merchantId
        self.dpaId = nil
        self.dpaClientId = nil
        self.dpaName = nil
        self.cardBrands = cardBrands
        self.isSandbox = isSandbox
        self.kid = kid
        self.publicKey = publicKey
        super.init()
    }

    /// Legacy constructor for merchants whose backend already provides DPA credentials. Prefer
    /// `init(merchantId:isSandbox:cardBrands:)` + `resolve(...)` for new integrations.
    @objc public init(dpaId: String,
                      dpaClientId: String? = nil,
                      cardBrands: [String] = ["visa", "mastercard"],
                      dpaName: String,
                      isSandbox: Bool = false,
                      kid: String? = nil,
                      publicKey: String? = nil) {
        self.merchantId = nil
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

    /// Fetches the DPA credentials (`dpaId`, `dpaClientId`, `dpaName`) from the gateway's
    /// `/config/merchants/{merchantId}/configs/vctp` endpoint and populates them on this
    /// config. The merchant should call this once per session, after authenticating, and
    /// before launching Click to Pay. The completion fires on the main queue.
    ///
    /// - Parameters:
    ///   - accessToken: bearer token used to authenticate the gateway request
    ///   - apiGatewayBaseUrl: e.g. `https://api-gateway.sandbox.ngenius-payments.com`
    ///   - completion: `nil` error on success; otherwise carries the underlying NSError
    @objc public func resolve(accessToken: String,
                              apiGatewayBaseUrl: String,
                              completion: @escaping (Error?) -> Void) {
        guard let merchantId = merchantId, !merchantId.isEmpty else {
            DispatchQueue.main.async {
                completion(NSError(domain: "ClickToPayConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "merchantId is required to resolve DPA credentials"]))
            }
            return
        }

        ClickToPayMerchantConfigService.fetch(
            merchantId: merchantId,
            accessToken: accessToken,
            apiGatewayBaseUrl: apiGatewayBaseUrl
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let resolved):
                    self?.dpaId = resolved.dpaId
                    self?.dpaClientId = resolved.dpaClientId
                    self?.dpaName = resolved.dpaName
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
        }
    }
}
