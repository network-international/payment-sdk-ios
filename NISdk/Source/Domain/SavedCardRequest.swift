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
    var visaRequest: VisaRequest?
    /// Selected Slice installment plan. Sent under `slice`, exactly as the manual-card
    /// route sends it — a saved card is as eligible for a plan as a freshly-typed one.
    var sliceRequest: SliceRequest?
    /// Payer device fields for Trident fraud screening, read when the body is encoded.
    var deviceInfo: PayerDeviceInfo = .current
    
    enum CodingKeys: String, CodingKey {
        case expiry
        case cardholderName
        case cardToken
        case cvv
        case payerIp
        case visaRequest = "vis"
        case sliceRequest = "slice"
        case deviceId
        case deviceOs
        case deviceType
    }
    
    override init() {
        expiry = nil
        cardToken = nil
        cvv = nil
        cardholderName = nil
        payerIp = nil
        visaRequest = nil
        sliceRequest = nil
    }
    
    init(expiry: String?, cardholderName: String?, cardToken: String?,
         cvv: String?) {
        self.expiry = expiry
        self.cardholderName = cardholderName
        self.cardToken = cardToken
        self.cvv = cvv
        visaRequest = nil
        sliceRequest = nil
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expiry = try container.decode(String.self, forKey: .expiry)
        cardholderName = try container.decode(String.self, forKey: .cardholderName)
        cardToken = try container.decode(String.self, forKey: .cardToken)
        cvv = try container.decode(String.self, forKey: .cvv)
        payerIp = try container.decode(String.self, forKey: .payerIp)
        visaRequest = try container.decode(VisaRequest.self, forKey: .visaRequest)
        sliceRequest = try container.decodeIfPresent(SliceRequest.self, forKey: .sliceRequest)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(expiry, forKey: .expiry)
        try container.encode(cvv, forKey: .cvv)
        try container.encode(cardholderName, forKey: .cardholderName)
        try container.encode(cardToken, forKey: .cardToken)
        try container.encode(payerIp, forKey: .payerIp)
        try container.encode(visaRequest, forKey: .visaRequest)
        try container.encodeIfPresent(sliceRequest, forKey: .sliceRequest)
        try container.encodeIfPresent(deviceInfo.deviceId, forKey: .deviceId)
        try container.encodeIfPresent(deviceInfo.deviceOs, forKey: .deviceOs)
        try container.encodeIfPresent(deviceInfo.deviceType, forKey: .deviceType)
    }
}
