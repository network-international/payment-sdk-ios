//
//  PaymentMediums.swift
//  NISdk
//
//  Created by Johnny Peter on 27/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc public enum PaymentMedium: Int, RawRepresentable  {
    case ApplePay
    case Card
    
    public var value: NIRawValue {
        switch self {
        case .ApplePay:
            return "ApplePay"
        case .Card:
            return "Card"
        }
    }
    
    public init?(value: NIRawValue) {
        switch value {
        case "ApplePay":
            self = .ApplePay
        case "Card":
            self = .Card
        default:
            self = .Card
        }
    }
}
