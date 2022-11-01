//
//  ThreeDSAuthenticationsRequest.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation

class ThreeDSAuthenticationsRequest: NSObject, Codable {
    var deviceChannel = "BRW"
    var threeDSCompInd: String?
    var notificationURL: String?
    var browserInfo: BrowserInfo
    
    override init() {
        self.threeDSCompInd = ""
        self.notificationURL = ""
        self.browserInfo = BrowserInfo()
    }
    
    init(threeDSCompInd: String, notificationURL: String, browserInfo: BrowserInfo) {
        self.threeDSCompInd = threeDSCompInd
        self.notificationURL = notificationURL
        self.browserInfo = browserInfo
    }
    
    func with(threeDSCompInd: String) -> ThreeDSAuthenticationsRequest {
        self.threeDSCompInd = threeDSCompInd
        return self
    }
    
    func with(notificationUrl: String) -> ThreeDSAuthenticationsRequest {
        self.notificationURL = notificationUrl
        return self
    }
    
    func with(browserInfo: BrowserInfo) -> ThreeDSAuthenticationsRequest {
        self.browserInfo = browserInfo
        return self
    }
}
