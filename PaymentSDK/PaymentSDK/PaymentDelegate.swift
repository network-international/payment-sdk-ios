//
//  PaymentDelegate.swift
//  PaymentSDK
//
//  Created by Niraj Chauhan on 2/27/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

@objc public protocol PaymentDelegate
{
    
    @objc func beginAuthorization(didSelect paymentMethod : PaymentSDK.PaymentMethod, handler completion: @escaping (PaymentAuthorizationLink?) -> Void)
    
    @objc func authorizationStarted()
    
    @objc func authorizationCompleted(withStatus status: AuthorizationStatus)
        
    @objc func paymentStarted()
    
    @objc func paymentCompleted(with status: PaymentStatus)
    
}

@objc public enum AuthorizationStatus: Int {
    case success
    case failed
}

@objc public enum PaymentStatus: Int {
    case success
    case failed
}
