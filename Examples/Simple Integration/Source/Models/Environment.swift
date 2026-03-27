//
//  Environment.swift
//  Simple Integration
//
//  Created by Gautam Chibde on 25/04/24.
//  Copyright © 2024 Network International. All rights reserved.
//

import Foundation

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
    let apiKey: String
    let outletReference: String
    let realm: String
    
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
        case apiKey
        case outletReference
        case realm
    }
    
    init(type: EnvironmentType, name: String, apiKey: String, outletReference: String, realm: String) {
        self.type = type
        self.id = UUID().uuidString
        self.name = name
        self.apiKey = apiKey
        self.outletReference = outletReference
        self.realm = realm
    }

    init(id: String, type: EnvironmentType, name: String, apiKey: String, outletReference: String, realm: String) {
        self.type = type
        self.id = id
        self.name = name
        self.apiKey = apiKey
        self.outletReference = outletReference
        self.realm = realm
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(EnvironmentType.self, forKey: .type)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        apiKey = try values.decode(String.self, forKey: .apiKey)
        outletReference = try values.decode(String.self, forKey: .outletReference)
        realm = try values.decode(String.self, forKey: .realm)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(outletReference, forKey: .outletReference)
        try container.encode(realm, forKey: .realm)
    }
    
    func getGateWayUrl() -> String {
        let region = Environment.getRegion();
        if(region == Region.KSA.rawValue) {
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
        let region = Environment.getRegion();
        if(region == Region.KSA.rawValue) {
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
    
    static func getOrderAction() -> String {
        if let action = UserDefaults.standard.string(forKey: KEY_ORDER_ACTION) {
            return action
        } else {
            return "SALE"
        }
    }
    
    static func setOrderAction(action: String) {
        UserDefaults.standard.set(action, forKey: KEY_ORDER_ACTION)
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

    static func setRegion(region: String) {
        UserDefaults.standard.set(region, forKey: KEY_REGION)
    }

    static func getRegion() -> String {
        if let region = UserDefaults.standard.string(forKey: KEY_REGION) {
            return region
        } else {
            return "UAE"
        }
    }

    static func setCurrency(currency: String) {
        UserDefaults.standard.set(currency, forKey: KEY_CURRENCY)
    }

    static func getCurrency() -> String {
        if let currency = UserDefaults.standard.string(forKey: KEY_CURRENCY) {
            return currency
        } else {
            return "AED"
        }
    }

    static func setOrderType(orderType: String) {
        UserDefaults.standard.set(orderType, forKey: KEY_ORDER_TYPE)
    }

    static func getOrderType() -> String {
        if let orderType = UserDefaults.standard.string(forKey: KEY_ORDER_TYPE) {
            return orderType
        } else {
            return ""
        }
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
