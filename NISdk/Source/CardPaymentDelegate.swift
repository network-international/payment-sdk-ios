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
    @objc optional func authorizationDidComplete(with status: String)
    
    // payment event cycles
    @objc optional func paymentDidBegin()
    @objc func paymentDidComplete(with status: String)
    
    // 3ds challenge cycles
    @objc optional func threeDSChallengeDidBegin()
    @objc optional func threeDSChallengeDidComplete(with status: String)
}
