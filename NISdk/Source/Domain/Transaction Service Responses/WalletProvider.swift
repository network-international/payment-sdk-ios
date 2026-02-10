//
//  File.swift
//  NISdk
//
//  Created by Johnny Peter on 27/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public enum WalletProvider: String, Codable, CaseIterable {
    case applePay = "APPLE_PAY"
    case samsungPay = "SAMSUNG_PAY"
    case chinaUnionPay = "UNION_PAY"
    case googlePay = "GOOGLE_PAY"
    case directApplePay = "DIRECT_APPLE_PAY"
    case directGooglePay = "DIRECT_GOOGLE_PAY"
    case visaClickToPay = "VISA_CLICK_TO_PAY"
    case directVisaClickToPay = "DIRECT_VISA_CLICK_TO_PAY"
}
