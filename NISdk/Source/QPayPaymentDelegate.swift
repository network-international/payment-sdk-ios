//
//  QPayPaymentDelegate.swift
//  NISdk
//

import Foundation

@objc public protocol QPayPaymentDelegate {
    @objc func qpayPaymentCompleted(with status: QPayPaymentStatus)
}

@objc public enum QPayPaymentStatus: Int {
    case success
    case failed
    case cancelled
    case invalidRequest
}
