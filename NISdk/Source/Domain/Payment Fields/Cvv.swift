//
//  cvv.swift
//  NISdk
//
//  Created by Johnny Peter on 21/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class Cvv {
    var value: String? {
        didSet {
            if let value = self.value {
                let isValid = self.validate()
                NotificationCenter.default.post(name: .didChangeCVV,
                                                object: self,
                                                userInfo: ["value": value, "isValid": isValid])
            }
        }
    }
    
    func validate() -> Bool {
        if let value = value {
            return Int(value) ?? 0 > 99 && Int(value) ?? 0 < 1000
        }
        return false
    }
}

