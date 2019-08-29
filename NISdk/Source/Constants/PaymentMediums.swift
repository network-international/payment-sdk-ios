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
    
    public var rawValue: RawValue {
        switch self {
        case .ApplePay:
            return "ApplePay"
        case .Card:
            return "Card"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "ApplePay":
            self = .ApplePay
        case "Card":
            self = .Card
        default:
            self = .Card
        }
    }
}
