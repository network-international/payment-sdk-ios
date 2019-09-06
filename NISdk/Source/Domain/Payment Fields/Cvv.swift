//
//  cvv.swift
//  NISdk
//
//  Created by Johnny Peter on 21/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

struct CVVLengths {
    static let normal: Int = 3
    static let amex: Int = 4
}

class Cvv {
    var length: Int = CVVLengths.normal
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
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateCvvMaxLenFor(_:)),
                                               name: .didChangePan, object: nil)
    }
    
    @objc func updateCvvMaxLenFor(_ notification: Notification) {
        if let data = notification.userInfo, let cardProvider = data["cardProvider"] as? CardProvider {
            if(cardProvider == .americanExpress) {
                self.length = CVVLengths.amex
            } else {
                self.length = CVVLengths.normal
            }
        }
    }
    
    func validate() -> Bool {
        if let value = value {
            return String(value).count == self.length
        }
        return false
    }
}

