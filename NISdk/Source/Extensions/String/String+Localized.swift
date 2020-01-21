//
//  String+Localized.swift
//  NISdk
//
//  Created by Johnny Peter on 06/09/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        let language = NISdk.sharedInstance.sdkLanguage
        let bundle = NISdk.sharedInstance.getBundleFor(language: language)
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }
    
    func localized(withComment:String) -> String {
        let bundle = NISdk.sharedInstance.getBundle()
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: withComment)
    }
}
