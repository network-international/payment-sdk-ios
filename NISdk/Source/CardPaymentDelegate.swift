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
    @objc func paymentDidComplete(with status: String)
    
    // 3ds challenge cycles
    @objc optional func threeDSChallengeDidBegin()
    @objc optional func threeDSChallengeDidComplete(with status: String)
}

@objc public enum AuthorizationStatus: Int, RawRepresentable  {
    case AuthSuccess
    case AuthFailed
    
    public typealias RawValue = String
    
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
