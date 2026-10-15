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
    /// Indicates the transaction originates from a native app; sent at the same
    /// level as `pan` in the `/card` payment request body.
    var deviceChannel: String = "BRW"
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
    var payerIp: String?
    var visaRequest: VisaRequest?
    var sliceRequest: SliceRequest?
    /// Payer device fields for Trident fraud screening, read when the body is encoded.
    var deviceInfo: PayerDeviceInfo = .current

    override init() {
        pan = nil
        expiryMonth = nil
        expiryYear = nil
        cvv = nil
        cardHolderName = nil
        visaRequest = nil
        sliceRequest = nil
    }
    
    init(pan: String, expiryMonth: String, expiryYear: String,
         cvv: String, cardHolderName: String) {
        self.pan = pan
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.cvv = cvv
        self.cardHolderName = cardHolderName
        self.visaRequest = nil
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
    
    func setPayerIp(payerIp: String) {
        self.payerIp = payerIp
    }
    
    enum CodingKeys: String, CodingKey {
        case pan
        case deviceChannel
        case expiry
        case cvv
        case payerIp
        case cardHolderName = "cardholderName"
        case visaRequest = "vis"
        case sliceRequest = "slice"
        case deviceId
        case deviceOs
        case deviceType
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pan = try container.decode(String.self, forKey: .pan)
        cvv = try container.decode(String.self, forKey: .cvv)
        cardHolderName = try container.decode(String.self, forKey: .cardHolderName)
        payerIp = try container.decode(String.self, forKey: .payerIp)
        visaRequest = try container.decode(VisaRequest.self, forKey: .visaRequest)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pan, forKey: .pan)
        try container.encode(deviceChannel, forKey: .deviceChannel)
        try container.encode(cvv, forKey: .cvv)
        try container.encode(cardHolderName, forKey: .cardHolderName)
        try container.encode(expiry, forKey: .expiry)
        try container.encode(payerIp, forKey: .payerIp)
        try container.encodeIfPresent(visaRequest, forKey: .visaRequest)
        try container.encodeIfPresent(sliceRequest, forKey: .sliceRequest)
        try container.encodeIfPresent(deviceInfo.deviceId, forKey: .deviceId)
        try container.encodeIfPresent(deviceInfo.deviceOs, forKey: .deviceOs)
        try container.encodeIfPresent(deviceInfo.deviceType, forKey: .deviceType)
    }
}
