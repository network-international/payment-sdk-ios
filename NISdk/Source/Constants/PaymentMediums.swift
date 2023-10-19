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
    case ThreeDSTwo
    case SavedCard
    
    public var rawVal: RawValue {
        switch self {
        case .ApplePay:
            return "ApplePay"
        case .Card:
            return "Card"
        case .ThreeDSTwo:
            return "ThreeDSTwo"
        case .SavedCard:
            return "SavedCard"
        }
    }
    
    public init?(rawVal: RawValue) {
        switch rawVal {
        case "ApplePay":
            self = .ApplePay
        case "Card":
            self = .Card
        case "ThreeDSTwo":
            self = .ThreeDSTwo
        default:
            self = .Card
        }
    }
}
