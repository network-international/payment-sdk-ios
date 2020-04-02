//
//  Amount.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct Amount: Codable {
    public let currencyCode: String?
    public let value: Double?
    
    private enum AmountCodingKeys: String, CodingKey {
        case currencyCode
        case value
    }
    
    func getMinorUnit() -> Int {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: NISdk.sharedInstance.sdkLanguage)
        formatter.currencyCode = self.currencyCode
        formatter.numberStyle = .currency
        let minorUnit = formatter.maximumFractionDigits
        return minorUnit
    }
    
    func getFormattedAmount() -> String {
        var orderAmountValue = ""
        if let value = value {
            let minorUnit = self.getMinorUnit()
            let exponent: Decimal = pow(10.00, minorUnit)
            let roundedValue = Decimal(value) / exponent
            orderAmountValue = "\(roundedValue)";
        }
        
        let language = NISdk.sharedInstance.sdkLanguage
        let direction = Locale.characterDirection(forLanguage: language)
        if (direction == .rightToLeft) {
            return "\(currencyCode ?? "") \(orderAmountValue)"
        } else {
            return "\(orderAmountValue) \(currencyCode ?? "")"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let AmountContainer = try decoder.container(keyedBy: AmountCodingKeys.self)
        currencyCode = try AmountContainer.decodeIfPresent(String.self, forKey: .currencyCode)
        value = try AmountContainer.decodeIfPresent(Double.self, forKey: .value)
    }
}
