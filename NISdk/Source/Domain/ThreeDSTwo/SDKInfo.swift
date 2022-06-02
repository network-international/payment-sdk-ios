//
//  SDKInfo.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation

class SDKInfo: NSObject, Codable {
    var sdkAppID: String
    var sdkEncData: String
    var sdkEphemPubKey: SDKEphemPubKey
    var sdkMaxTimeout: Int
    var sdkReferenceNumber: String
    var sdkTransID: String
    var deviceRenderOptions: DeviceRenderOptions
    
    internal init(sdkAppID: String, sdkEncData: String, sdkEphemPubKey: SDKEphemPubKey, sdkMaxTimeout: Int, sdkReferenceNumber: String, sdkTransID: String, deviceRenderOptions: DeviceRenderOptions) {
        self.sdkAppID = sdkAppID
        self.sdkEncData = sdkEncData
        self.sdkEphemPubKey = sdkEphemPubKey
        self.sdkMaxTimeout = sdkMaxTimeout
        self.sdkReferenceNumber = sdkReferenceNumber
        self.sdkTransID = sdkTransID
        self.deviceRenderOptions = deviceRenderOptions
    }
}
