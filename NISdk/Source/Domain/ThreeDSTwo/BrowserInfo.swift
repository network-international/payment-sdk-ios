//
//  BrowserInfo.swift
//  NISdk
//
//  Created by Johnny Peter on 31/10/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation

class BrowserInfo: NSObject, Codable {
    var browserLanguage: String?
    var browserJavaEnabled: Bool?
    var browserColorDepth: String?
    var browserScreenHeight: String?
    var browserScreenWidth: String?
    var browserTZ: String?
    var browserUserAgent: String?
    var browserIP: String?
    var browserAcceptHeader: String?
    var browserJavascriptEnabled: Bool?
    var challengeWindowSize: String?
    
    func with(browserLanguage: String) -> BrowserInfo {
        self.browserLanguage = browserLanguage
        return self
    }
    
    func with(browserJavaEnabled: Bool) -> BrowserInfo {
        self.browserJavaEnabled = browserJavaEnabled
        return self
    }
    
    func with(browserColorDepth: String) -> BrowserInfo {
        self.browserColorDepth = browserColorDepth
        return self
    }
    
    func with(browserScreenHeight: String) -> BrowserInfo {
        self.browserScreenHeight = browserScreenHeight
        return self
    }
    
    func with(browserScreenWidth: String) -> BrowserInfo {
        self.browserScreenWidth = browserScreenWidth
        return self
    }
    
    func with(browserTZ: String) -> BrowserInfo {
        self.browserTZ = browserTZ
        return self
    }
    
    func with(browserUserAgent: String) -> BrowserInfo {
        self.browserUserAgent = browserUserAgent
        return self
    }
    
    func with(browserIP: String) -> BrowserInfo {
        self.browserIP = browserIP
        return self
    }
    
    func with(browserAcceptHeader: String) -> BrowserInfo {
        self.browserAcceptHeader = browserAcceptHeader
        return self
    }
    
    func with(browserJavascriptEnabled: Bool) -> BrowserInfo {
        self.browserJavascriptEnabled = browserJavascriptEnabled
        return self
    }
    
    func with(challengeWindowSize: String) -> BrowserInfo {
        self.challengeWindowSize = challengeWindowSize
        return self
    }
}
