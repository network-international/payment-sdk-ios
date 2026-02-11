//
//  DeviceFingerprint.swift
//  NISdk
//
//  Created by Prasath R on 11/12/25.
//  Copyright © 2025 Network International. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto

class DeviceFingerprint {

    static let shared = DeviceFingerprint()
    private init() {}

    private let key = "nisdk.deviceFingerprint"

    func fingerprint() -> String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }

        let newUUID = UUID().uuidString
        UserDefaults.standard.set(newUUID, forKey: key)
        return newUUID
    }
}
