//
//  Name.swift
//  NISdk
//
//  Created by Johnny Peter on 22/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class CardHolderName {
    var value: String? {
        didSet {
            if let value = self.value {
                let isValid = self.validateCardHolderName()
                NotificationCenter.default.post(name: .didChangeCardHolderName,
                                                object: self,
                                                userInfo: ["value": value, "isValid": isValid])
            }
        }
    }
    
    func validateCardHolderName() -> Bool {
        return true
    }    
}
