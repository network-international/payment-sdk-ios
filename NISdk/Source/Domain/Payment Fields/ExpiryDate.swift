//
//  ExpiryDate.swift
//  NISdk
//
//  Created by Johnny Peter on 22/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class ExpiryDate {
    var month: String? {
        didSet {
            notifyDateChange()
        }
    }

    var year: String? {
        didSet {
            notifyDateChange()
        }
    }

    func notifyDateChange() {
        let month = self.month ?? ""
        let year = self.year ?? ""
        let isValid = self.validate()
        
        NotificationCenter.default.post(name: .didChangeExpiryDate,
                                            object: self,
                                            userInfo: ["month": month,
                                                       "year": year,
                                                       "isValid": isValid])
    }
    
    func validate() -> Bool {
        if let month = month, let year = year {
            let expiryString = "20\(year)-\(month)"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM"
            let expiryDate = dateFormatter.date(from: expiryString)
            return expiryDate?.timeIntervalSinceNow.sign == .plus
        }
        return false
    }
}
