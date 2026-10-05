//
//  Environment.swift
//  Simple Integration
//
//  Created by Gautam Chibde on 25/04/24.
//  Copyright © 2024 Network International. All rights reserved.
//

import Foundation
import NISdk

enum EnvironmentType:String, Codable {
    case DEV = "DEV"
    case UAT = "UAT"
    case PROD = "PROD"
}

enum Region:String, Codable {
    case UAE = "UAE"
    case KSA = "KSA"
}

enum OrderType:String, Codable {
    case RECURRING = "RECURRING"
    case UNSCHEDULED = "UNSCHEDULED"
    case INSTALLMENT = "INSTALLMENT"
}

struct MerchantAttribute: Codable {
    let id: String
    let key: String
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case key
        case value
    }
    
    init(key: String, value: String) {
        self.id = UUID().uuidString
        self.key = key
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        key = try values.decode(String.self, forKey: .key)
        value = try values.decode(String.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(key, forKey: .key)
        try container.encode(value, forKey: .value)
    }
}

struct Environment: Codable, Identifiable {
    let type: EnvironmentType
    let id: String
    let name: String
    let nickname: String
    let apiKey: String
    let outletReference: String
    let realm: String
    /// Gateway region this outlet lives on. UAE and KSA are physically separate deployments with
    /// their own identity endpoints, so an outlet's credentials only work against one of them —
    /// which makes the region a property of the outlet, not an app-wide setting.
    let region: Region
    /// Currency this outlet transacts in. Alternative payment methods follow the acquirer, so the
    /// currency and the available methods travel together: a BHD outlet is the Benefit one, a QAR
    /// outlet is the QPay one. Pairing them here makes a mismatched combination unrepresentable.
    let currency: String
    /// Order action (SALE / PURCHASE / AUTH) this outlet is exercised with. Which actions an
    /// outlet accepts is outlet configuration — Slice, for one, only supports PURCHASE — so
    /// pairing it with the outlet stops a global picker from being wrong for half of them.
    let orderAction: String
    /// Order type (SINGLE / RECURRING / UNSCHEDULED / INSTALLMENT). Empty means SINGLE.
    /// Enabled per outlet like the action, so it travels with it.
    let orderType: String
    /// Payment methods the gateway offered for this outlet, captured on import.
    /// Informational: shown on the tile so an outlet's capabilities are visible without
    /// opening it or starting a payment. Empty for an outlet added by hand.
    let paymentMethods: [String]
    let applePayMerchantId: String
    /// Merchant identifier used by the Click to Pay config endpoint
    /// (`/config/merchants/{merchantId}/configs/vctp`). Distinct from `outletReference`.
    let clickToPayMerchantId: String
    
    /// Currencies offerable on an outlet. One list, so the add form, the edit sheet and
    /// anything else that needs it cannot drift apart.
    static let supportedCurrencies = [
        "AED", "SAR", "BHD", "QAR", "KWD", "OMR", "JOD", "USD", "EUR", "GBP",
        "AUD", "BRL", "CAD", "CHF", "CNY", "HKD", "INR", "JPY", "KRW", "MXN",
        "NOK", "NZD", "SEK", "SGD", "TRY", "ZAR", "DZD", "ILS", "LYD", "TND", "ZWG",
    ]

    private static let KEY_SAVED_ENVIRONMENT_ID = "saved_env_id"
    private static let KEY_SAVED_ENVIRONMENTS = "saved_environments"
    private static let KEY_ORDER_ACTION = "order_action"
    private static let KEY_REGION = "region"
    private static let KEY_CURRENCY = "currency"
    private static let KEY_ORDER_TYPE = "order_type"
    private static let KEY_SAVED_LANGUAGE = "saved_language"
    private static let KEY_SAVED_MERCHANT_ATTRIBUTES = "merchant_attributes"

    // SDK Color keys
    private static let KEY_SDK_COLOR_PAY_BUTTON = "sdk_color_pay_button"
    private static let KEY_SDK_COLOR_PAY_BUTTON_TEXT = "sdk_color_pay_button_text"
    private static let KEY_SDK_COLOR_PAY_BUTTON_DISABLED = "sdk_color_pay_button_disabled"
    private static let KEY_SDK_COLOR_PAY_BUTTON_DISABLED_TEXT = "sdk_color_pay_button_disabled_text"
    private static let KEY_SDK_COLOR_INPUT_FIELD_BG = "sdk_color_input_field_bg"
    private static let KEY_SDK_COLOR_AUTH_VIEW_BG = "sdk_color_auth_view_bg"
    private static let KEY_SDK_COLOR_AUTH_VIEW_INDICATOR = "sdk_color_auth_view_indicator"
    private static let KEY_SDK_COLOR_AUTH_VIEW_LABEL = "sdk_color_auth_view_label"
    private static let KEY_SDK_COLOR_3DS_VIEW_BG = "sdk_color_3ds_view_bg"
    private static let KEY_SDK_COLOR_3DS_VIEW_LABEL = "sdk_color_3ds_view_label"
    private static let KEY_SDK_COLOR_3DS_VIEW_INDICATOR = "sdk_color_3ds_view_indicator"
    
    enum CodingKeys: String, CodingKey {
        case type
        case id
        case name
        case nickname
        case apiKey
        case outletReference
        case realm
        case region
        case currency
        case orderAction
        case orderType
        case paymentMethods
        case applePayMerchantId
        case clickToPayMerchantId
    }

    init(type: EnvironmentType, nickname: String = "", apiKey: String, outletReference: String, realm: String, region: Region = .UAE, currency: String = "AED", orderAction: String = "SALE", orderType: String = "", paymentMethods: [String] = [], applePayMerchantId: String = "", clickToPayMerchantId: String = "") {
        self.init(id: UUID().uuidString, type: type, nickname: nickname, apiKey: apiKey,
                  outletReference: outletReference, realm: realm, region: region, currency: currency,
                  orderAction: orderAction, orderType: orderType, paymentMethods: paymentMethods,
                  applePayMerchantId: applePayMerchantId, clickToPayMerchantId: clickToPayMerchantId)
    }

    init(id: String, type: EnvironmentType, nickname: String = "", apiKey: String, outletReference: String, realm: String, region: Region = .UAE, currency: String = "AED", orderAction: String = "SALE", orderType: String = "", paymentMethods: [String] = [], applePayMerchantId: String = "", clickToPayMerchantId: String = "") {
        self.type = type
        self.id = id
        self.nickname = nickname
        self.name = nickname.isEmpty ? realm : nickname
        self.apiKey = apiKey
        self.outletReference = outletReference
        self.realm = realm
        self.region = region
        self.currency = currency
        self.orderAction = orderAction
        self.orderType = orderType
        self.paymentMethods = paymentMethods
        self.applePayMerchantId = applePayMerchantId
        self.clickToPayMerchantId = clickToPayMerchantId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(EnvironmentType.self, forKey: .type)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        nickname = try values.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        apiKey = try values.decode(String.self, forKey: .apiKey)
        outletReference = try values.decode(String.self, forKey: .outletReference)
        realm = try values.decode(String.self, forKey: .realm)
        applePayMerchantId = try values.decodeIfPresent(String.self, forKey: .applePayMerchantId) ?? ""
        clickToPayMerchantId = try values.decodeIfPresent(String.self, forKey: .clickToPayMerchantId) ?? ""
        // Environments saved before region/currency/orderAction/orderType moved onto the outlet
        // inherit whatever the app-wide pickers were last set to, so an existing install keeps
        // working as it did.
        region = try values.decodeIfPresent(Region.self, forKey: .region)
            ?? Region(rawValue: Environment.legacyGlobalRegion()) ?? .UAE
        currency = try values.decodeIfPresent(String.self, forKey: .currency)
            ?? Environment.legacyGlobalCurrency()
        orderAction = try values.decodeIfPresent(String.self, forKey: .orderAction)
            ?? Environment.legacyGlobalOrderAction()
        orderType = try values.decodeIfPresent(String.self, forKey: .orderType)
            ?? Environment.legacyGlobalOrderType()
        paymentMethods = try values.decodeIfPresent([String].self, forKey: .paymentMethods) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(outletReference, forKey: .outletReference)
        try container.encode(realm, forKey: .realm)
        try container.encode(region, forKey: .region)
        try container.encode(currency, forKey: .currency)
        try container.encode(orderAction, forKey: .orderAction)
        try container.encode(orderType, forKey: .orderType)
        try container.encode(paymentMethods, forKey: .paymentMethods)
        try container.encode(applePayMerchantId, forKey: .applePayMerchantId)
        try container.encode(clickToPayMerchantId, forKey: .clickToPayMerchantId)
    }

    /// Base API gateway URL (without trailing path) used by the Click to Pay merchant config
    /// endpoint and any other host-level calls. Derived from the same region/env logic as the
    /// transactions URL above.
    func getApiGatewayBaseUrl() -> String {
        if region == .KSA {
            switch type {
            case .DEV:  return "https://api-gateway.dev.ksa.ngenius-payments.com"
            case .UAT:  return "https://api-gateway.sandbox.ksa.ngenius-payments.com"
            case .PROD: return "https://api-gateway.ksa.ngenius-payments.com"
            }
        }
        switch type {
        case .DEV:  return "https://api-gateway-dev.ngenius-payments.com"
        case .UAT:  return "https://api-gateway.sandbox.ngenius-payments.com"
        case .PROD: return "https://api-gateway.ngenius-payments.com"
        }
    }
    
    func getGateWayUrl() -> String {
        if region == .KSA {
            return switch type {
            case .DEV:
                "https://api-gateway.dev.ksa.ngenius-payments.com/transactions/outlets/\(outletReference)/orders"
            case .UAT:
                "https://api-gateway.sandbox.ksa.ngenius-payments.com/transactions/outlets/\(outletReference)/orders"
            case .PROD:
                "https://api-gateway.ksa.ngenius-payments.com/transactions/outlets/\(outletReference)/orders"
            }
        }
        return switch type {
        case .DEV:
            "https://api-gateway-dev.ngenius-payments.com/transactions/outlets/\(outletReference)/orders"
        case .UAT:
            "https://api-gateway.sandbox.ngenius-payments.com/transactions/outlets/\(outletReference)/orders"
        case .PROD:
            "https://api-gateway.ngenius-payments.com/transactions/outlets/\(outletReference)/orders"
        }
    }
    
    func getIdentityUrl() -> String {
        if region == .KSA {
            return switch type {
                case .DEV:
                    "https://api-gateway.dev.ksa.ngenius-payments.com/identity/auth/access-token"
                case .UAT:
                    "https://api-gateway.sandbox.ksa.ngenius-payments.com/identity/auth/access-token"
                case .PROD:
                    "https://api-gateway.ksa.ngenius-payments.com/identity/auth/access-token"
                }
        }
        return switch type {
        case .DEV:
            "https://api-gateway-dev.ngenius-payments.com/identity/auth/access-token"
        case .UAT:
            "https://api-gateway.sandbox.ngenius-payments.com/identity/auth/access-token"
        case .PROD:
            "https://api-gateway.ngenius-payments.com/identity/auth/access-token"
        }
    }
    
    static func saveEnvironments(environments: [Environment]) {
        let jsonEncoder = JSONEncoder()
        if let encodedData = try? jsonEncoder.encode(environments) {
            UserDefaults.standard.set(encodedData, forKey: KEY_SAVED_ENVIRONMENTS)
        } else {
            print("Error encoding environments")
        }
    }
    
    static func saveMerchantAttributes(merchantAttributes: [MerchantAttribute]) {
        let jsonEncoder = JSONEncoder()
        if let encodedData = try? jsonEncoder.encode(merchantAttributes) {
            UserDefaults.standard.set(encodedData, forKey: KEY_SAVED_MERCHANT_ATTRIBUTES)
        } else {
            print("Error encoding MerchantAttribute")
        }
    }
    
    static func getEnvironments() -> [Environment] {
        if let data = UserDefaults.standard.data(forKey: KEY_SAVED_ENVIRONMENTS) {
            do {
                return try JSONDecoder().decode([Environment].self, from: data)
            } catch _ {
                return []
            }
        } else {
            return []
        }
    }
    
    static func getMerchantAttributes() -> [MerchantAttribute] {
        if let data = UserDefaults.standard.data(forKey: KEY_SAVED_MERCHANT_ATTRIBUTES) {
            do {
                return try JSONDecoder().decode([MerchantAttribute].self, from: data)
            } catch _ {
                return []
            }
        } else {
            return []
        }
    }
    
    // MARK: - Apple Pay certificate (POC)

    /// NI's own Apple Pay merchant identifier — the identity the hosted pay page uses, and
    /// the one whose processing certificate NI holds. Already listed in the app's
    /// in-app-payments entitlement. Change this to run the POC against a different NI
    /// identity (e.g. the KSA or production pay page).
    static let niApplePayMerchantId = "merchant.com.ngenius-payments.paypage-sandbox"
    private static let useNIApplePayCertificateKey = "useNIApplePayCertificate"

    /// When true the Apple Pay sheet is presented with NI's merchant identifier and the
    /// token is posted as a web-flow payment, so the gateway decrypts it with NI's
    /// certificate. When false the customer's own identifier and uploaded certificate are
    /// used. Setting it also pushes the flag into the SDK, so the two cannot disagree.
    static var useNIApplePayCertificate: Bool {
        get { UserDefaults.standard.bool(forKey: useNIApplePayCertificateKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: useNIApplePayCertificateKey)
            NISdk.sharedInstance.useNIApplePayCertificate = newValue
        }
    }

    static func getSelectedEnvironment() -> String? {
        if let savedEnvironmentId = UserDefaults.standard.string(forKey: KEY_SAVED_ENVIRONMENT_ID) {
            return savedEnvironmentId
        } else {
            return nil
        }
    }
    
    static func setSelectedEnvironment(environmentId: String) {
        UserDefaults.standard.set(environmentId, forKey: KEY_SAVED_ENVIRONMENT_ID)
    }

    /// Clears the selection, for when the selected environment is deleted and there is
    /// nothing left to fall back to.
    static func clearSelectedEnvironment() {
        UserDefaults.standard.removeObject(forKey: KEY_SAVED_ENVIRONMENT_ID)
    }
    
    /// Order action of the currently selected outlet. Falls back to the pre-migration global.
    static func selectedOrderAction() -> String {
        current()?.orderAction ?? legacyGlobalOrderAction()
    }

    /// Order type of the currently selected outlet; empty means SINGLE.
    static func selectedOrderType() -> String {
        current()?.orderType ?? legacyGlobalOrderType()
    }

    static func legacyGlobalOrderAction() -> String {
        UserDefaults.standard.string(forKey: KEY_ORDER_ACTION) ?? "SALE"
    }

    static func legacyGlobalOrderType() -> String {
        UserDefaults.standard.string(forKey: KEY_ORDER_TYPE) ?? ""
    }
    
    static func setLanguage(language: String) {
        UserDefaults.standard.set(language, forKey: KEY_SAVED_LANGUAGE)
    }
    
    static let supportedLanguages: Set<String> = ["en", "ar", "fr"]

    static func getLanguage() -> String {
        if let saved = UserDefaults.standard.string(forKey: KEY_SAVED_LANGUAGE) {
            return saved
        }
        let deviceLanguage = Locale.current.languageCode ?? "en"
        return supportedLanguages.contains(deviceLanguage) ? deviceLanguage : "en"
    }

    /// Region/currency used to live here as app-wide settings, independent of the selected
    /// outlet — which is what forced a tester to set the currency separately (and correctly)
    /// before an outlet's payment methods would appear. They are now carried by `Environment`;
    /// these readers exist only so environments saved by an older build can inherit them once.
    static func legacyGlobalRegion() -> String {
        UserDefaults.standard.string(forKey: KEY_REGION) ?? "UAE"
    }

    static func legacyGlobalCurrency() -> String {
        UserDefaults.standard.string(forKey: KEY_CURRENCY) ?? "AED"
    }

    /// Region of the currently selected outlet, for the few call sites that need it without an
    /// `Environment` to hand. Falls back to the pre-migration global.
    static func selectedRegion() -> Region {
        current()?.region ?? Region(rawValue: legacyGlobalRegion()) ?? .UAE
    }

    /// Currency of the currently selected outlet. This is the single source of truth for the
    /// order's currency — there is no longer a separate picker that can disagree with it.
    static func selectedCurrency() -> String {
        current()?.currency ?? legacyGlobalCurrency()
    }

    /// The environment currently selected, if any.
    static func current() -> Environment? {
        guard let id = getSelectedEnvironment() else { return nil }
        return getEnvironments().first { $0.id == id }
    }


    // MARK: - SDK Colors

    static func setSDKColor(_ key: String, hex: String) {
        UserDefaults.standard.set(hex, forKey: key)
    }

    static func getSDKColor(_ key: String) -> String {
        return UserDefaults.standard.string(forKey: key) ?? ""
    }

    static var sdkColorPayButton: String {
        get { getSDKColor(KEY_SDK_COLOR_PAY_BUTTON) }
        set { setSDKColor(KEY_SDK_COLOR_PAY_BUTTON, hex: newValue) }
    }

    static var sdkColorPayButtonText: String {
        get { getSDKColor(KEY_SDK_COLOR_PAY_BUTTON_TEXT) }
        set { setSDKColor(KEY_SDK_COLOR_PAY_BUTTON_TEXT, hex: newValue) }
    }

    static var sdkColorPayButtonDisabled: String {
        get { getSDKColor(KEY_SDK_COLOR_PAY_BUTTON_DISABLED) }
        set { setSDKColor(KEY_SDK_COLOR_PAY_BUTTON_DISABLED, hex: newValue) }
    }

    static var sdkColorPayButtonDisabledText: String {
        get { getSDKColor(KEY_SDK_COLOR_PAY_BUTTON_DISABLED_TEXT) }
        set { setSDKColor(KEY_SDK_COLOR_PAY_BUTTON_DISABLED_TEXT, hex: newValue) }
    }

    static var sdkColorInputFieldBg: String {
        get { getSDKColor(KEY_SDK_COLOR_INPUT_FIELD_BG) }
        set { setSDKColor(KEY_SDK_COLOR_INPUT_FIELD_BG, hex: newValue) }
    }

    static var sdkColorAuthViewBg: String {
        get { getSDKColor(KEY_SDK_COLOR_AUTH_VIEW_BG) }
        set { setSDKColor(KEY_SDK_COLOR_AUTH_VIEW_BG, hex: newValue) }
    }

    static var sdkColorAuthViewIndicator: String {
        get { getSDKColor(KEY_SDK_COLOR_AUTH_VIEW_INDICATOR) }
        set { setSDKColor(KEY_SDK_COLOR_AUTH_VIEW_INDICATOR, hex: newValue) }
    }

    static var sdkColorAuthViewLabel: String {
        get { getSDKColor(KEY_SDK_COLOR_AUTH_VIEW_LABEL) }
        set { setSDKColor(KEY_SDK_COLOR_AUTH_VIEW_LABEL, hex: newValue) }
    }

    static var sdkColorThreeDSViewBg: String {
        get { getSDKColor(KEY_SDK_COLOR_3DS_VIEW_BG) }
        set { setSDKColor(KEY_SDK_COLOR_3DS_VIEW_BG, hex: newValue) }
    }

    static var sdkColorThreeDSViewLabel: String {
        get { getSDKColor(KEY_SDK_COLOR_3DS_VIEW_LABEL) }
        set { setSDKColor(KEY_SDK_COLOR_3DS_VIEW_LABEL, hex: newValue) }
    }

    static var sdkColorThreeDSViewIndicator: String {
        get { getSDKColor(KEY_SDK_COLOR_3DS_VIEW_INDICATOR) }
        set { setSDKColor(KEY_SDK_COLOR_3DS_VIEW_INDICATOR, hex: newValue) }
    }
}
