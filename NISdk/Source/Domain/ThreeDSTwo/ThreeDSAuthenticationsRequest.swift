//
//  ThreeDSAuthenticationsRequest.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation

class ThreeDSAuthenticationsRequest: NSObject, Codable {
    var deviceChannel = "APP"
    var sdkInfo: SDKInfo
    
    init(sdkInfo: SDKInfo) {
        self.sdkInfo = sdkInfo
    }
}
