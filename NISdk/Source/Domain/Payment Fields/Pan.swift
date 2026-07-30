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

    // The schemes the outlet actually accepts (order.paymentMethods.card). When set,
    // card detection is scoped to these — so a card whose BIN belongs to a scheme the
    // outlet does not support is not shown (matches the Android CardDetector, which is
    // constructed with the supported cards). nil means "detect across all schemes".
    var allowedCardProviders: Set<CardProvider>? = nil

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
        case .mada: return #"^(446404|440795|440647|421141|474491|588845|457997|457865|468540|468541|468542|468543|417633|446393|636120|410621|409201|403024|458456|462220|455708|484783|455036|486094|486095|486096|504300|440533|489318|489319|445564|410685|406996|432328|428671|428672|428673|446672|543357|434107|412565|431361|604906|521076|588850|529415|535825|543085|524130|554180|549760|516138|515079|555610|524514|529741|537767|535989|536023|513213|520058|558563|422817|422818|422819|410834|428331|483010|483011|483012|406136|419593|439954|407520|530060|531196|420132|442463|524940|492464|442429)\d{10}|(968208|968201|968205|968203|968211|968206|968202|968209|968204|968207|968212)\d{9}|(45488707|40177800|40719700|40739500|45501701|49098000|40545400|49098001|40728100|22337902|22337986|53973776|52166100|22402030|42222200|45488713)\d{8}$"#
        case .visa: return "^4[0-9]{12}(?:[0-9]{3})?$"
        case .masterCard: return "^5[1-5][0-9]{14}$"
        case .americanExpress: return "^3[47][0-9]{13}$"
        case .dinersClubInternational: return "^3(?:0[0-5]|[68][0-9])[0-9]{11}$"
        case .discover: return "^6(?:011|5[0-9]{2})[0-9]{12}$"
        case .jcb: return "^(?:2131|1800|35\\d{3})\\d{11}$"
        // Jaywan — UAE domestic card scheme. Recognised by IINs 6690 and 9784,
        // 16-digit PAN (matches the Android SDK's Jaywan BIN ranges).
        case .jaywan: return "^(6690|9784)[0-9]{12}$"
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
    
    // MARK: - Card scheme detection (early, IIN/BIN based)

    // A single IIN (BIN) range: the numbers lo...hi, each `len` digits long.
    private struct IINRange {
        let lo: UInt64
        let hi: UInt64
        let len: Int
    }

    // IIN ranges per scheme, most-specific first. Derived from the full-PAN
    // patterns above (the mada BIN list, 5[1-5], 4, …) so early detection agrees
    // with full-length detection — it just resolves as soon as the IIN is typed
    // instead of waiting for the whole card number.
    private static let iinRanges: [(CardProvider, [IINRange])] = {
        func r(_ lo: UInt64, _ hi: UInt64, _ len: Int) -> IINRange { IINRange(lo: lo, hi: hi, len: len) }
        let mada6: [UInt64] = [403024, 406136, 406996, 407520, 409201, 410621, 410685, 410834, 412565, 417633, 419593, 420132, 421141, 422817, 422818, 422819, 428331, 428671, 428672, 428673, 431361, 432328, 434107, 439954, 440533, 440647, 440795, 442429, 442463, 445564, 446393, 446404, 446672, 455036, 455708, 457865, 457997, 458456, 462220, 468540, 468541, 468542, 468543, 474491, 483010, 483011, 483012, 484783, 486094, 486095, 486096, 489318, 489319, 492464, 504300, 513213, 515079, 516138, 520058, 521076, 524130, 524514, 524940, 529415, 529741, 530060, 531196, 535825, 535989, 536023, 537767, 543085, 543357, 549760, 554180, 555610, 558563, 588845, 588850, 604906, 636120, 968201, 968202, 968203, 968204, 968205, 968206, 968207, 968208, 968209, 968211, 968212]
        let mada8: [UInt64] = [22337902, 22337986, 22402030, 40177800, 40545400, 40719700, 40728100, 40739500, 42222200, 45488707, 45488713, 45501701, 49098000, 49098001, 52166100, 53973776]
        var mada = mada6.map { r($0, $0, 6) }
        mada.append(contentsOf: mada8.map { r($0, $0, 8) })
        return [
            (.mada, mada),
            (.jaywan, [r(6690, 6690, 4), r(9784, 9784, 4)]),
            (.americanExpress, [r(34, 34, 2), r(37, 37, 2)]),
            (.masterCard, [r(51, 55, 2)]),
            (.dinersClubInternational, [r(300, 305, 3), r(36, 36, 2), r(38, 38, 2)]),
            (.discover, [r(6011, 6011, 4), r(65, 65, 2)]),
            (.jcb, [r(2131, 2131, 4), r(1800, 1800, 4), r(35, 35, 2)]),
            (.visa, [r(4, 4, 1)])
        ]
    }()

    private static func pow10(_ n: Int) -> UInt64 {
        var result: UInt64 = 1
        for _ in 0..<max(0, n) { result *= 10 }
        return result
    }

    // How the typed digits relate to one IIN range.
    // .confirmed(len) — the digits already contain this IIN (len = how many digits matched).
    // .potential      — fewer digits than the IIN, but still a possible prefix of it.
    private enum IINMatch { case confirmed(Int); case potential; case none }

    private func match(_ digits: String, against range: IINRange) -> IINMatch {
        let count = digits.count
        if count >= range.len {
            guard let prefix = UInt64(digits.prefix(range.len)) else { return .none }
            return (prefix >= range.lo && prefix <= range.hi) ? .confirmed(range.len) : .none
        }
        // Fewer digits than the IIN — the input spans [value·10^d, value·10^d + 10^d - 1];
        // it is a potential match if that span overlaps the range.
        guard let value = UInt64(digits) else { return .none }
        let scale = Pan.pow10(range.len - count)
        let low = value * scale
        let high = low + scale - 1
        return (high >= range.lo && low <= range.hi) ? .potential : .none
    }

    // Detects the card scheme as early as possible from the IIN (BIN) prefix,
    // rather than only once the full card number is entered. A scheme is returned
    // as soon as the typed digits contain its IIN (the longest / most-specific IIN
    // wins, so e.g. a mada BIN is preferred over the broad Visa/Mastercard ranges).
    // Before any IIN is fully typed, a scheme is still returned once it is the only
    // one the digits could still belong to; otherwise `.unknown`.
    func getCardProvider() -> CardProvider {
        guard let digits = value?.filter({ $0.isNumber }), !digits.isEmpty else {
            return .unknown
        }
        var bestConfirmed: (provider: CardProvider, len: Int)?
        var possible = Set<CardProvider>()
        for (provider, ranges) in Pan.iinRanges {
            // Scope detection to the schemes the outlet supports (when known), so an
            // unsupported scheme's card is never surfaced.
            if let allowed = allowedCardProviders, !allowed.contains(provider) { continue }
            // Jaywan shares its short 6690/9784 prefix with a wider space; only
            // commit to it once 8 digits are entered so it isn't shown prematurely.
            if provider == .jaywan && digits.count < Pan.jaywanMinDigits { continue }
            for range in ranges {
                switch match(digits, against: range) {
                case .confirmed(let len):
                    if bestConfirmed == nil || len > bestConfirmed!.len {
                        bestConfirmed = (provider, len)
                    }
                case .potential:
                    possible.insert(provider)
                case .none:
                    break
                }
            }
        }
        if let best = bestConfirmed { return best.provider }
        return possible.count == 1 ? possible.first! : .unknown
    }

    // Jaywan is only detected once this many digits have been entered.
    private static let jaywanMinDigits = 8
}
