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

struct Environment: Codable {
    let type: EnvironmentType
    let id: String
    let name: String
    let apiKey: String
    let outletReference: String
    let realm: String
    
    private static let KEY_SAVED_ENVIRONMENT_ID = "saved_env_id"
    private static let KEY_SAVED_ENVIRONMENTS = "saved_environments"
    
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
        return switch type {
        case .DEV:
            "https://api-gateway-dev.ngenius-payments.com/identity/auth/access-token"
        case .UAT:
            "https://api-gateway-sandbox.platform.network.ae/identity/auth/access-token"
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
}
