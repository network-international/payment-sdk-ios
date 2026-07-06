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
    // Single source of truth for the mada BIN prefixes, shared by the full-length
    // pattern (getPatternFor) and the early BIN pattern (getBinPatternFor) so the
    // two lists can never drift apart. Groups mirror the original mada regex:
    // six-digit BINs, the 968* six-digit BINs, and the eight-digit BINs.
    static let madaBins6 = "446404|440795|440647|421141|474491|588845|457997|457865|468540|468541|468542|468543|417633|446393|636120|410621|409201|403024|458456|462220|455708|484783|455036|486094|486095|486096|504300|440533|489318|489319|445564|410685|406996|432328|428671|428672|428673|446672|543357|434107|412565|431361|604906|521076|588850|529415|535825|543085|524130|554180|549760|516138|515079|555610|524514|529741|537767|535989|536023|513213|520058|558563|422817|422818|422819|410834|428331|483010|483011|483012|406136|419593|439954|407520|530060|531196|420132|442463|524940|492464|442429"
    static let madaBins6Alt = "968208|968201|968205|968203|968211|968206|968202|968209|968204|968207|968212"
    static let madaBins8 = "45488707|40177800|40719700|40739500|45501701|49098000|40545400|49098001|40728100|22337902|22337986|53973776|52166100|22402030|42222200|45488713"

    func getPatternFor(cardType: CardProvider) -> String {
        switch cardType  {
        case .mada: return "^(\(Pan.madaBins6))\\d{10}|(\(Pan.madaBins6Alt))\\d{9}|(\(Pan.madaBins8))\\d{8}$"
        case .visa: return "^4[0-9]{12}(?:[0-9]{3})?$"
        case .masterCard: return "^5[1-5][0-9]{14}$"
        case .americanExpress: return "^3[47][0-9]{13}$"
        case .dinersClubInternational: return "^3(?:0[0-5]|[68][0-9])[0-9]{11}$"
        case .discover: return "^6(?:011|5[0-9]{2})[0-9]{12}$"
        case .jcb: return "^(?:2131|1800|35\\d{3})\\d{11}$"
        default: return ""
        }
    }

    // Prefix-only patterns that identify the scheme from the leading (BIN) digits,
    // so the brand icon can be shown before the full card number is entered. These
    // are unanchored on the right and carry no length requirement, so they match a
    // partial number as soon as the issuer prefix is unambiguous.
    func getBinPatternFor(cardType: CardProvider) -> String {
        switch cardType {
        case .mada: return "^(\(Pan.madaBins6)|\(Pan.madaBins6Alt)|\(Pan.madaBins8))"
        case .visa: return "^4"
        case .masterCard: return "^5[1-5]"
        case .americanExpress: return "^3[47]"
        case .dinersClubInternational: return "^3(?:0[0-5]|[68])"
        case .discover: return "^6(?:011|5)"
        case .jcb: return "^(?:2131|1800|35)"
        default: return ""
        }
    }

    func matches(pattern: String, value: String) -> Bool {
        if pattern.isEmpty { return false }
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            return regex.matches(in: value,
                                 options: [],
                                 range: NSMakeRange(0, value.count)).count > 0
        } catch {
            return false
        }
    }

    func testFor(cardType: CardProvider, value: String) -> Bool {
        return matches(pattern: getPatternFor(cardType: cardType), value: value)
    }

    func testForBin(cardType: CardProvider, value: String) -> Bool {
        return matches(pattern: getBinPatternFor(cardType: cardType), value: value)
    }

    func getCardProvider() -> CardProvider {
        guard let cardNumber = self.value, !cardNumber.isEmpty else { return .unknown }
        // Definitive match once the full card number is present. Iterating in
        // CardProvider.allCases order preserves the existing scheme precedence, so
        // a completed PAN resolves to exactly the same provider as before.
        for cardType in CardProvider.allCases where cardType != .unknown {
            if testFor(cardType: cardType, value: cardNumber) { return cardType }
        }
        // Early match on a partial PAN: as soon as the leading digits (BIN) identify
        // the scheme, return it so the card-type icon updates without waiting for the
        // whole number. Same iteration order keeps precedence consistent with above.
        for cardType in CardProvider.allCases where cardType != .unknown {
            if testForBin(cardType: cardType, value: cardNumber) { return cardType }
        }
        return .unknown
    }
}
