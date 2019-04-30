import Foundation

struct CardCVVFieldFormatUtility
{
    static func preview(forText text : String?, maxDigits: Int) -> String
    {
        guard var digits = text else { return PreviewDefault.CVV3 }
        digits = CardNumberFormatUtility.digitsOnly(forText: digits)
        
        let digitCount = digits.count
        let required = maxDigits - digitCount
        
        guard required > 0 else { return digits }
        
        var preview = ""
        for _ in 1...required {
            preview += "0"
        }
        
        return (digits + preview)
    }
    
    static func reformatInputField(forText text : String?) -> String?
    {
        guard var digits = text else { return text }
        digits = CardNumberFormatUtility.digitsOnly(forText: digits)
        return digits
    }
}
