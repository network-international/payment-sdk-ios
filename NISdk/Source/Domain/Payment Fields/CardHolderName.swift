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
                let isValid = self.validate()
                NotificationCenter.default.post(name: .didChangeCardHolderName,
                                                object: self,
                                                userInfo: ["value": value, "isValid": isValid])
            }
        }
    }
    
    func validate() -> Bool {
        if let value = value {
            let numbersRange = value.rangeOfCharacter(from: .decimalDigits)
            return value.count > 0 && numbersRange == nil
        }
        return false
    }    
}
