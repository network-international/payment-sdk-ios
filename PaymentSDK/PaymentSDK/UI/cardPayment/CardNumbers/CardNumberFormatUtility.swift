import Foundation

struct CardNumberFormatUtility
{
    static func digitsOnly(forText text: String? ) -> String
    {
        guard var digits = text else { return "" }
        let decimalDigits = CharacterSet.decimalDigits
        digits = String(digits.unicodeScalars.filter(decimalDigits.contains))
        return digits
    }

}
