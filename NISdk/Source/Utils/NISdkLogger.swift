//
//  NISdkLogger.swift
//  NISdk
//
//  Centralised os_log categories for the SDK.
//

import Foundation
import os.log

enum NISdkLogger {
    private static let subsystem = "com.networkinternational.NISdk"

    static let sdk = OSLog(subsystem: subsystem, category: "SDK")
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let auth = OSLog(subsystem: subsystem, category: "Auth")
    static let payment = OSLog(subsystem: subsystem, category: "Payment")
    static let aani = OSLog(subsystem: subsystem, category: "AaniPay")
}
