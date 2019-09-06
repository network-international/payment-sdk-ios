//
//  NotificationTypes.swift
//  NISdk
//
//  Created by Johnny Peter on 22/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let didChangePan = Notification.Name("didChangePan")
    static let didChangeCVV = Notification.Name("didChangeCVV")
    static let didChangeExpiryDate = Notification.Name("didChangeExpiryDate")
    static let didChangeCardHolderName = Notification.Name("didChangeCardHolderName")
}
