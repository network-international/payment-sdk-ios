//
//  NIPayment.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class PaymentRequest: NSObject, Codable {
    var pan: String?
    var expiryMonth: String?
    var expiryYear: String?
    var cvv: String?
    var cardHolderName: String?
    var expiry: String {
        get {
            if let expiryMonth = expiryMonth, let expiryYear = expiryYear {
                return "20\(expiryYear)-\(expiryMonth)"
            } else {
                return ""
            }
        }
    }
    
    override init() {
        pan = nil
        expiryMonth = nil
        expiryYear = nil
        cvv = nil
        cardHolderName = nil
    }
    
    init(pan: String, expiryMonth: String, expiryYear: String,
         cvv: String, cardHolderName: String) {
        self.pan = pan
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.cvv = cvv
        self.cardHolderName = cardHolderName
    }
    
    func set(pan: String) {
        self.pan = pan
    }
    
    func set(expiryMonth: String) {
        self.expiryMonth = expiryMonth
    }
    
    func set(expiryYear: String) {
        self.expiryYear = expiryYear
    }
    
    func set(cardHolderName: String) {
        self.cardHolderName = cardHolderName
    }
    
    func set(cvv: String) {
        self.cvv = cvv
    }
    
    enum CodingKeys: String, CodingKey {
        case pan
        case expiry
        case cvv
        case cardHolderName = "cardholderName"
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pan = try container.decode(String.self, forKey: .pan)
        cvv = try container.decode(String.self, forKey: .cvv)
        cardHolderName = try container.decode(String.self, forKey: .cardHolderName)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pan, forKey: .pan)
        try container.encode(cvv, forKey: .cvv)
        try container.encode(cardHolderName, forKey: .cardHolderName)
        try container.encode(expiry, forKey: .expiry)
    }
}
