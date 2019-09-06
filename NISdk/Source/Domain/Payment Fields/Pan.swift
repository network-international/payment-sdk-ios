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
        didSet { notifyPanChange() }
    }
    
    var cardProvider: CardProvider {
        get { return getCardProvider() }
    }
    
    var trimmedValue: String? {
        get { return value?.removeWhitespace()}
    }
    
    var formattedValue: String? {
        get { return value }
    }
    
    func validate() -> Bool {
        if let value = self.value {
            return value.isValidLuhn()
        }
        return false
    }
    
    func notifyPanChange() {
        var userInfo: [String: Any] = [:]
        let isValid = self.validate()
        if let value = self.value {
            userInfo["value"] = value
            userInfo["isValid"] = isValid
            userInfo["cardProvider"] = self.cardProvider
            NotificationCenter.default.post(name: .didChangePan,
                                            object: self,
                                            userInfo: userInfo)
        }
    }
}

extension Pan {
    func getPatternFor(cardType: CardProvider) -> String {
        switch cardType  {
        case .visa: return "^4[0-9]{12}(?:[0-9]{3})?$"
        case .masterCard: return "^5[1-5][0-9]{14}$"
        case .americanExpress: return "^3[47][0-9]{13}$"
        case .dinersClubInternational: return "^3(?:0[0-5]|[68][0-9])[0-9]{11}$"
        case .discover: return "^6(?:011|5[0-9]{2})[0-9]{12}$"
        case .jcb: return "^(?:2131|1800|35\\d{3})\\d{11}$"
        default: return ""
        }
    }
    
    func testFor(cardType: CardProvider, value: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: getPatternFor(cardType: cardType),
                                                options: .caseInsensitive)
            return regex.matches(in: value,
                                 options: [],
                                 range: NSMakeRange(0, value.count)).count > 0
        } catch {
            return false
        }
    }
    
    func getCardProvider() -> CardProvider {
        var possibleCardType: CardProvider = .unknown;
        if let cardNumber = self.value {
            for cardType in CardProvider.allCases {
                if (cardType != .unknown && testFor(cardType: cardType, value: cardNumber)){
                    possibleCardType = cardType
                    break
                }
            }
        }
        return possibleCardType
    }
}
