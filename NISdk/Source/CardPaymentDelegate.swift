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
    // Called when the 3DS challenge is terminated by the SDK before completion
    // (e.g. the ACS/Cardinal challenge page failed to load or render in time).
    // `errorCode` is a stable, machine-readable reason such as
    // `THREE_DS_ACS_LOAD_TIMEOUT` — see `ThreeDSErrorCode`. The customer-facing
    // payment result still arrives via `paymentDidComplete(with:)`.
    @objc optional func threeDSChallengeDidFail(withErrorCode errorCode: String)
    @objc optional func partialAuthBegin()
}

// Stable SDK error codes surfaced via `threeDSChallengeDidFail(withErrorCode:)`.
// These are diagnostic reasons for the merchant; they never contain customer
// data or full ACS URLs.
@objc public class ThreeDSErrorCode: NSObject {
    // The ACS / Cardinal challenge page did not load or render within the
    // SDK's initial-load timeout window.
    @objc public static let acsLoadTimeout = "THREE_DS_ACS_LOAD_TIMEOUT"
    // The ACS / Cardinal challenge navigation failed (TLS, DNS, reset, blocked).
    @objc public static let acsLoadFailed = "THREE_DS_ACS_LOAD_FAILED"
    // The overall 3DS session exceeded its wall-clock cap without completing
    // (a stall in any phase: fingerprint, auth calls, challenge, or response).
    @objc public static let threeDSTimeout = "THREE_DS_TIMEOUT"
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
