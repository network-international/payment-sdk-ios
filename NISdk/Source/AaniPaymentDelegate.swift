//
//  AaniPaymentDelegate.swift
//  NISdk
//
//  Created by Gautam Chibde on 29/08/24.
//

import Foundation

@objc public protocol AaniPaymentDelegate {
    @objc func aaniPaymentCompleted(with status: AaniPaymentStatus)
}
