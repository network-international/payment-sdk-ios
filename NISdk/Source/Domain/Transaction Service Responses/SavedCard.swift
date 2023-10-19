//
//  SavedCard.swift
//  NISdk
//
//  Created by Gautam Chibde on 06/09/23.
//

import Foundation

public struct SavedCard: Codable {

    public var maskedPan: String?
    public var expiry: String?
    public var cardholderName: String?
    public var scheme: String?
    public var cardToken: String?
    public var recaptureCsc: Bool = false
    
    public init() {
        self.maskedPan = nil
        self.expiry = nil
        self.cardholderName = nil
        self.scheme = nil
        self.cardToken = nil
        self.recaptureCsc = false
    }
    
    public init(maskedPan: String, expiry: String, cardholderName: String, scheme: String, cardToken: String, recaptureCsc: Bool) {
        self.maskedPan = maskedPan
        self.expiry = expiry
        self.cardholderName = cardholderName
        self.scheme = scheme
        self.cardToken = cardToken
        self.recaptureCsc = recaptureCsc
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.maskedPan = try container.decode(String.self, forKey: .maskedPan)
        self.expiry = try container.decode(String.self, forKey: .expiry)
        self.cardholderName = try container.decode(String.self, forKey: .cardholderName)
        self.scheme = try container.decode(String.self, forKey: .scheme)
        self.cardToken = try container.decode(String.self, forKey: .cardToken)
        self.recaptureCsc = try container.decode(Bool.self, forKey: .recaptureCsc)
    }
}
