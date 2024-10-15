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
    @objc optional func partialAuthBegin()
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
    case InValidRequest
    case PaymentPostAuthReview
    case PartialAuthDeclined
    case PartialAuthDeclineFailed
    case PartiallyAuthorised
    
    public var rawVal: RawValue {
        switch self {
        case.PaymentSuccess:
            return "PaymentSuccess"
        case .PaymentFailed:
            return "PaymentFailed"
        case .PaymentCancelled:
            return "PaymentCancelled"
        case .InValidRequest:
            return "InValidRequest"
        case .PaymentPostAuthReview:
            return "PaymentPostAuthReview"
        case .PartialAuthDeclined:
            return "PARTIAL_AUTH_DECLINED"
        case .PartialAuthDeclineFailed:
            return "PARTIAL_AUTH_DECLINE_FAILED"
        case .PartiallyAuthorised:
            return "PARTIALLY_AUTHORISED"
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
        case "InValidRequest":
            self = .InValidRequest
        case "PaymentPostAuthReview":
            self = .PaymentPostAuthReview
        case "PARTIAL_AUTH_DECLINED":
            self = .PartialAuthDeclined
        case "PARTIAL_AUTH_DECLINE_FAILED":
            self = .PartialAuthDeclineFailed
        case "PARTIALLY_AUTHORISED":
            self = .PartiallyAuthorised
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
