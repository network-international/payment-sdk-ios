import Foundation

struct EndDateValidation
{
    
    static func isValid(date: String) -> Bool
    {
        switch date.count
        {
        case 0  : return true
        case 1  : return validfirstDigit(endDate: date)
        case 2  : return validFirstTwoDigits(endDate: date)
        case 3  : return validFirstThreeDigits(endDate: date)
        case 4  : return validFourDigits(endDate: date)
        default        : return false
        }
    }
    
    private static func validfirstDigit(endDate digit: String) -> Bool
    {
        log("")
        let value = Int(digit) ?? 0
        return (value >= 0) && (value <= 9)
    }
    
    private static func validFirstTwoDigits(endDate digits: String) -> Bool
    {
        log("")
        let value = Int(digits) ?? 0
        return self.validMonth(value)
    }
    
    private static func validFirstThreeDigits(endDate digits: String) -> Bool
    {
        log("")
        guard self.validMonth(inLongerString: digits) else
        {
            return false
        }
        let yearFragment = digits.suffix(1)
        let value = Int(yearFragment) ?? 0
        return value > 0 && value < 4 // update this in 2025 as it supports cards valid until 2039
    }
 
    private static func validFourDigits(endDate digits: String) -> Bool
    {
        log("")
        guard self.validMonth(inLongerString: digits) else
        {
            return false
        }
        
        let date = cardDate(forDigits: digits) ?? CardDate.veryOldExpiryDate()
        return isValid(date, currentDate: DateUtility.currentDate())
    }
    
    private static func isValid(_ date: CardDate, currentDate: CardDate) -> Bool
    {
        guard isValidExpiryYear(date.year, currentYear: currentDate.year) else
        {
            return false
        }
        
        let sameYear = (date.year == currentDate.year)
        if sameYear && (date.month.rawValue < currentDate.month.rawValue)
        {
            return false
        }
        
        return true
    }
    
    private static func cardDate(forDigits digits: String) -> CardDate?
    {
        switch digits.count
        {
        case 4,5  : return cardDate(for4Digits:digits)
        default   : return nil
        }
    }
    
    private static func cardDate(for4Digits digits: String) -> CardDate
    {
        let monthDigits = digits.prefix(2)
        let yearDigits  = digits.suffix(2)
        let monthValue  = Int(monthDigits) ?? 0
        let yearValue   = Int(yearDigits) ?? 0
        let month = CardDate.Month(rawValue: monthValue) ?? .Jan
        let year  = yearValue + DateUtility.currentCentury()
        return CardDate(month: month, year: year, kind: .expiry)
    }
    
    
    private static func validMonth(inLongerString full: String) -> Bool
    {
        let month = full.prefix(2)
        let value = Int(month) ?? 0
        return self.validMonth(value)
    }
    
    private static func validMonth(_ month: Int) -> Bool
    {
        if month < CardDate.Month.Jan.rawValue || month > CardDate.Month.Dec.rawValue
        {
            return false
        }
        return true
    }
    
    struct Const
    {
        static let maxCardValidityYears = 15
    }
}


extension EndDateValidation
{
    private static func isValidExpiryYear(_ expiryYear: Int,
                                          currentYear : Int) -> Bool
    {
        guard expiryYear >= currentYear else //TODO: take into account 2 month old card can be valid
        {
            return false
        }
        
        let maxYear = currentYear + Const.maxCardValidityYears
        
        guard expiryYear <= maxYear else
        {
            return false
        }
        return true
    }

}
