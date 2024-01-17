//
//  SavedCardRequesy.swift
//  NISdk
//
//  Created by Gautam Chibde on 05/10/23.
//

import Foundation


class SavedCardRequest: NSObject, Codable {
    var expiry: String?
    var cardholderName: String?
    var cardToken: String?
    var cvv: String?
    var payerIp: String?
    
    enum CodingKeys: String, CodingKey {
        case expiry
        case cardholderName
        case cardToken
        case cvv
        case payerIp
    }
    
    override init() {
        expiry = nil
        cardToken = nil
        cvv = nil
        cardholderName = nil
        payerIp = nil
    }
    
    init(expiry: String?, cardholderName: String?, cardToken: String?,
         cvv: String?) {
        self.expiry = expiry
        self.cardholderName = cardholderName
        self.cardToken = cardToken
        self.cvv = cvv
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expiry = try container.decode(String.self, forKey: .expiry)
        cardholderName = try container.decode(String.self, forKey: .cardholderName)
        cardToken = try container.decode(String.self, forKey: .cardToken)
        cvv = try container.decode(String.self, forKey: .cvv)
        payerIp = try container.decode(String.self, forKey: .payerIp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(expiry, forKey: .expiry)
        try container.encode(cvv, forKey: .cvv)
        try container.encode(cardholderName, forKey: .cardholderName)
        try container.encode(cardToken, forKey: .cardToken)
        try container.encode(payerIp, forKey: .payerIp)
    }
}
