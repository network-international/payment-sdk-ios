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

struct Environment: Codable {
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
    private static let KEY_SAVED_LANGUAGE = "saved_language"
    private static let KEY_SAVED_MERCHANT_ATTRIBUTES = "merchant_attributes"
    
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
            "https://api-gateway-sandbox.platform.network.ae/transactions/outlets/\(outletReference)/orders"
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
            "https://api-gateway-uat.ngenius-payments.com/identity/auth/access-token"
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
    
    static func getLanguage() -> String {
        if let action = UserDefaults.standard.string(forKey: KEY_SAVED_LANGUAGE) {
            return action
        } else {
            return "en"
        }
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
}
