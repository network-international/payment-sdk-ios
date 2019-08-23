//
//  NIPaymentContextDelegate.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc public protocol CardPaymentDelegate {
    
    // authorisation event cycles
    @objc optional func authorizationWillBegin()
    @objc optional func authorizationDidBegin()
    @objc func authorizationDidComplete(with status: AuthorizationStatus)
    
    // payment event cycles
    @objc optional func paymentDidBegin()
    @objc func paymentDidComplete(with status: PaymentStatus)
    
    // 3ds challenge cycles
    @objc optional func threeDSChallengeDidBegin()
    @objc optional func threeDSChallengeDidComplete(with status: String)
}

public typealias RawValue = String
@objc public enum AuthorizationStatus: Int, RawRepresentable  {
    case AuthSuccess
    case AuthFailed
    
    public var rawValue: RawValue {
        switch self {
        case .AuthSuccess:
            return "AuthSuccess"
        case .AuthFailed:
            return "AuthFailed"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "AuthSuccess":
            self = .AuthSuccess
        case "AuthFailed":
            self = .AuthFailed
        default:
            self = .AuthFailed
        }
    }
}

@objc public enum PaymentStatus: Int, RawRepresentable {
    case PaymentSuccess
    case PaymentFailed
    
    public var rawValue: RawValue {
        switch self {
        case.PaymentSuccess:
            return "PaymentSuccess"
        case .PaymentFailed:
            return "PaymentFailed"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "PaymentSuccess":
            self = .PaymentSuccess
        case "PaymentFailed":
            self = .PaymentFailed
        default:
            self = .PaymentSuccess
        }
    }
}
