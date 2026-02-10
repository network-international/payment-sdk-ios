//
//  ClickToPayDelegate.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation

/// Status of a Click to Pay payment
@objc public enum ClickToPayStatus: Int, RawRepresentable {
    case success
    case failed
    case cancelled
    case postAuthReview

    public var rawVal: RawValue {
        switch self {
        case .success: return "success"
        case .failed: return "failed"
        case .cancelled: return "cancelled"
        case .postAuthReview: return "postAuthReview"
        }
    }

    public init?(rawVal: RawValue) {
        switch rawVal {
        case "success": self = .success
        case "failed": self = .failed
        case "cancelled": self = .cancelled
        case "postAuthReview": self = .postAuthReview
        default: self = .failed
        }
    }
}

/// Delegate protocol for Click to Pay payment callbacks
@objc public protocol ClickToPayDelegate {
    /// Called when the Click to Pay flow completes
    @objc func clickToPayDidComplete(with status: ClickToPayStatus)
}
