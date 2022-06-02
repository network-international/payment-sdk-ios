//
//  DeviceRenderOptions.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation

class DeviceRenderOptions: NSObject, Codable {
    var sdkInterface: String
    var sdkUiType: [String]
    
    internal init(sdkInterface: String, sdkUiType: [String]) {
        self.sdkInterface = sdkInterface
        self.sdkUiType = sdkUiType
    }
}
