import UIKit

struct CardPANFieldFormatUtility
{
    static func preview(forText text    : String?,
                        layoutDirection : UIUserInterfaceLayoutDirection,
                        maxLengthsPAN   : [Int]) -> String
    {
        guard var digits = text else { return PreviewDefault.PAN }
        digits = CardNumberFormatUtility.digitsOnly(forText: digits)
        
        let maxDigits = maxLengthsPAN.max() ?? 19
        let digitCount = digits.count
        let required = maxDigits - digitCount
        
        guard required > 0 else { return formattedDigits(digits, PANLengths: maxLengthsPAN) }
        
        var preview = ""
        for _ in 1...required {
            preview += "0"
        }
        
        switch layoutDirection
        {
        case .rightToLeft: fallthrough
        case .leftToRight: preview = (digits + preview)
        }
        
        return formattedDigits(preview, PANLengths: maxLengthsPAN)
    }
    
    static func reformatInputField(forText text     : String?,
                                   layoutDirection  : UIUserInterfaceLayoutDirection,
                                   maxLengthsPAN    : [Int]) -> String?
    {
        guard var digits = text else { return text }
        digits = CardNumberFormatUtility.digitsOnly(forText: digits)
        return self.formattedDigits(digits, PANLengths: maxLengthsPAN)
    }
    
    static func formattedDigits(_ digits: String,
                                PANLengths: [Int]) -> String
    {
        let pattern = self.patternForPANLengths(PANLengths)
        switch pattern
        {
        case .spaceEvery4   : return self.spaceEvery4Formatted(digits: digits)
        case .spaces_4_6_5  : return self.spaces_4_6_5Formatted(digits: digits)
        default             : return self.spaceEvery4Formatted(digits: digits)
        }
    }
    
    static func spaceEvery4Formatted(digits: String) -> String
    {
        var result = ""
        for (index, digit) in digits.enumerated()
        {
            if (index % 4) == 0 && index != 0
            {
                result += " " + String(digit)
                continue
            }
            result += String(digit)
        }
        return result
    }
    
    static func spaces_4_6_5Formatted(digits: String) -> String
    {
        var result = ""
        for (index, digit) in digits.enumerated()
        {
            if (index == 4) || (index == 10)
            {
                result += " " + String(digit)
                continue
            }
            result += String(digit)
        }
        return result
    }
    
    enum DigitsPattern
    {
        case spaceEvery4
        case spaces_4_6_5
        case spaces_6_13
        case spaces_4_4_5
        case spaces_4_5_6
    }
    
    static func patternForPANLengths(_ lengths: [Int]) -> DigitsPattern
    {
        guard let firstLength = lengths.first else
        {
            return .spaceEvery4
        }
        
        if lengths.count == 1 && firstLength == 15 //TODO: could also be 4-5-6, get brand to know
        {
            return .spaces_4_6_5
        }
        
        return .spaceEvery4
    }
}
