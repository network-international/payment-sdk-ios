//
//  Pan.swift
//  NISdk
//
//  Created by Johnny Peter on 21/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class Pan {
     var value: String? {
        didSet {
            if let value = self.value {
                let isValid = self.validatePan()
                NotificationCenter.default.post(name: .didChangePan,
                                                object: self,
                                                userInfo: ["value": value, "isValid": isValid])
            }
        }
    }
    
    func validatePan() -> Bool {
        return true
    }
}

