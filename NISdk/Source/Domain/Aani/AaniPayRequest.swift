//
//  AaniPayRequest.swift
//  NISdk
//
//  Created by Gautam Chibde on 07/08/24.
//

import Foundation

class AaniPayRequest: NSObject, Codable {
    let aliasType: String
    let payerIp: String
    let backLink: String
    let source: String
    var mobileNumber: MobileNumber?
    var emiratesId: String?
    var passportId: String?
    var emailId: String?
    
    init(aliasType: String, payerIp: String, backLink: String) {
        self.aliasType = aliasType
        self.payerIp = payerIp
        self.backLink = backLink
        self.source = "MOBILE_APP"
        self.mobileNumber = nil
        self.emiratesId = nil
        self.emailId = nil
        self.passportId = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case aliasType
        case payerIp
        case backLink
        case source
        case mobileNumber
        case emiratesId
        case passportId
        case emailId
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.aliasType = try container.decode(String.self, forKey: .aliasType)
        self.payerIp = try container.decode(String.self, forKey: .payerIp)
        self.backLink = try container.decode(String.self, forKey: .backLink)
        self.source = try container.decode(String.self, forKey: .source)
        self.mobileNumber = try container.decodeIfPresent(MobileNumber.self, forKey: .mobileNumber)
        self.emiratesId = try container.decodeIfPresent(String.self, forKey: .emiratesId)
        self.passportId = try container.decodeIfPresent(String.self, forKey: .passportId)
        self.emailId = try container.decodeIfPresent(String.self, forKey: .emailId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(aliasType, forKey: .aliasType)
        try container.encode(payerIp, forKey: .payerIp)
        try container.encode(backLink, forKey: .backLink)
        try container.encode(source, forKey: .source)
        try container.encode(mobileNumber, forKey: .mobileNumber)
        try container.encode(emiratesId, forKey: .emiratesId)
        try container.encode(passportId, forKey: .passportId)
        try container.encode(emailId, forKey: .emailId)
    }
}

class MobileNumber: NSObject, Codable {
    let countryCode: String
    let number: String
    
    init(countryCode: String, number: String) {
        self.countryCode = countryCode
        self.number = number
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.countryCode = try container.decode(String.self, forKey: .countryCode)
        self.number = try container.decode(String.self, forKey: .number)
    }
    
    enum CodingKeys: String, CodingKey {
        case countryCode
        case number
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encode(number, forKey: .number)
    }
}
