import Foundation

struct CardExpiryDateFieldFormatUtility
{
    static func preview(forText text : String?) -> String
    {
        guard let digits = text else { return PreviewDefault.endDate }
        let length = digits.count
        switch length
        {
        case 1  : return digits + "M/YY"
        case 2  : return digits + "/YY"
        case 3  : return digits + "YY"
        case 4  : return digits + "Y"
        case 5  : return digits
        default : return PreviewDefault.endDate
        }
    }
    
    static func reformatInputField(forText text : String?) -> String?
    {
        guard var digits = text else { return text }
        digits = CardNumberFormatUtility.digitsOnly(forText: digits)
        return self.formattedDigits(digits)
    }
    
    static func formattedDigits(_ digits: String) -> String
    {
        guard digits.count != 1 else
        {
            return addLeadingZeroIfNeeded(toDigit: digits)
        }
        
        var formatted = ""
        for (index, charcter) in digits.enumerated()
        {
            if index == 2
            {
                formatted.append("/")
            }
            formatted.append(charcter)
        }
        
        return formatted
    }
    
    private static func addLeadingZeroIfNeeded(toDigit digit: String) -> String
    {
        guard digit != "0" || digit != "1" else
        {
            return digit
        }
        
        let value = Int(digit) ?? 0
        
        if value >= 2 && value <= 9
        {
            return "0" + digit
        }
        
        return digit
    }

}
