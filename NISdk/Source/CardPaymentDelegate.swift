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
    @objc optional func authorizationDidComplete(with status: AuthorizationStatus)
    
    // payment event cycles
    @objc optional func paymentDidBegin()
    @objc func paymentDidComplete(with status: PaymentStatus)
    
    // 3ds challenge cycles
    @objc optional func threeDSChallengeDidBegin()
    @objc optional func threeDSChallengeDidComplete(with status: ThreeDSStatus)
}

public typealias RawValue = String
@objc public enum AuthorizationStatus: Int, RawRepresentable  {
    case AuthSuccess
    case AuthFailed
    
    public var rawVal: RawValue {
        switch self {
        case .AuthSuccess:
            return "AuthSuccess"
        case .AuthFailed:
            return "AuthFailed"
        }
    }
    
    public init?(rawVal: RawValue) {
        switch rawVal {
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
    case PaymentCancelled
    
    public var rawVal: RawValue {
        switch self {
        case.PaymentSuccess:
            return "PaymentSuccess"
        case .PaymentFailed:
            return "PaymentFailed"
        case .PaymentCancelled:
            return "PaymentCancelled"
        }
    }
    
    public init?(rawVal: RawValue) {
        switch rawVal {
        case "PaymentSuccess":
            self = .PaymentSuccess
        case "PaymentFailed":
            self = .PaymentFailed
        case "PaymentCancelled":
            self = .PaymentCancelled
        default:
            self = .PaymentCancelled
        }
    }
}

@objc public enum ThreeDSStatus: Int, RawRepresentable {
    case ThreeDSSuccess
    case ThreeDSFailed
    
    public var rawVal: RawValue {
        switch self {
        case.ThreeDSSuccess:
            return "ThreeDSSuccess"
        case .ThreeDSFailed:
            return "ThreeDSFailed"
        }
    }
    
    public init?(rawVal: RawValue) {
        switch rawVal {
        case "ThreeDSSuccess":
            self = .ThreeDSSuccess
        case "ThreeDSFailed":
            self = .ThreeDSFailed
        default:
            self = .ThreeDSSuccess
        }
    }

}
