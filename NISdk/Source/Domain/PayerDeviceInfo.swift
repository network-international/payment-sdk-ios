//
//  PayerDeviceInfo.swift
//  NISdk
//

import UIKit

/// The payer device fields Trident screens payments with, sent at the top level of every card and
/// wallet payment body. Every field is optional on the gateway, so a value that cannot be read is
/// left out rather than holding up the payment.
///
/// `browserName`, `deviceName` and `fingerprint` are not sent: the SDK is not a browser, and the
/// other two have no agreed value yet.
struct PayerDeviceInfo {

    static let deviceIdKey = "deviceId"
    static let deviceOsKey = "deviceOs"
    static let deviceTypeKey = "deviceType"

    static let mobile = "Mobile"
    static let tablet = "Tablet"

    /// The gateway rejects longer values for every field except `deviceId`.
    static let maxLength = 100

    /// `identifierForVendor`, the mechanism Trident asked for: it needs no permission and is stable
    /// for this vendor's apps on the device. iOS returns nil for it briefly after a restart, before
    /// the device is first unlocked.
    let deviceId: String?
    let deviceOs: String?
    let deviceType: String?

    /// Trident wants the platform name only, with no version — iPadOS included, as the same SDK.
    static let iOS = "iOS"

    init(deviceId: String?, deviceOs: String? = PayerDeviceInfo.iOS, idiom: UIUserInterfaceIdiom) {
        self.deviceId = deviceId.flatMap { $0.isEmpty ? nil : $0 }
        self.deviceOs = deviceOs.flatMap { $0.isEmpty ? nil : String($0.prefix(PayerDeviceInfo.maxLength)) }
        switch idiom {
        case .phone: self.deviceType = PayerDeviceInfo.mobile
        case .pad: self.deviceType = PayerDeviceInfo.tablet
        default: self.deviceType = nil
        }
    }

    static var current: PayerDeviceInfo {
        let device = UIDevice.current
        return PayerDeviceInfo(deviceId: device.identifierForVendor?.uuidString,
                               idiom: device.userInterfaceIdiom)
    }

    /// The fields that have a value, keyed as the gateway names them.
    var fields: [String: String] {
        var fields: [String: String] = [:]
        fields[PayerDeviceInfo.deviceIdKey] = deviceId
        fields[PayerDeviceInfo.deviceOsKey] = deviceOs
        fields[PayerDeviceInfo.deviceTypeKey] = deviceType
        return fields
    }

    /// Adds the fields to a JSON object body that the SDK passes through rather than builds — Apple
    /// Pay's `paymentData` (`data`, `header`, `signature`, `version`). Apple signs the values inside
    /// the token, not its JSON text, so re-encoding leaves it verifiable. Keys the body already has
    /// are kept, and a body that is not a JSON object is returned untouched.
    func adding(toJSONObject body: Data) -> Data {
        let extra = fields
        guard !extra.isEmpty,
              var object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] else {
            return body
        }
        for (key, value) in extra where object[key] == nil {
            object[key] = value
        }
        return (try? JSONSerialization.data(withJSONObject: object, options: [.withoutEscapingSlashes])) ?? body
    }
}
