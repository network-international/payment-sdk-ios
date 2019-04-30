import Foundation

struct PANValidation
{
    static func maxLengthsPAN(forCard card: CardIdentity?) -> [Int]
    {
        guard let cardIdentity = card, cardIdentity.description != nil else { return [Default.PANLength] }
        guard let ranges = cardIdentity.matchingRanges else { return [Default.PANLength] }
        var lengths : [Int] = []
        for range in ranges
        {
            let PANLengths = range.PANLengths
            if PANLengths.count > 0
            {
                lengths.append(contentsOf: PANLengths)
            }
        }
        let sortedLengths = lengths.sorted()
        return sortedLengths
    }
    
    static func lengthStatePAN(_ PAN        : String,
                               cardIdentity : CardIdentity?) -> PANLengthState
    {
        guard let card = cardIdentity else { return [] }
        let availableLengths = self.maxLengthsPAN(forCard: card)
        var state = self.lengthStatePAN(PAN, availableLengths: availableLengths)
        
        if (card.description == nil || card.certainty == .none) && state.contains(.isValid)
        {
            state.remove(.isValid)
        }
        return state
    }
    
    private static func lengthStatePAN(_ PAN            : String,
                                       availableLengths : [Int]) -> PANLengthState
    {
        let numberOfDigits = PAN.count
        var state : PANLengthState = []
        
        if self.validLuhn(forDigits: PAN)
        {
            state.insert(.isValid)
        }
        
        if availableLengths.count == 1
        {
            return lengthStatePANLength(numberOfDigits,
                                        availableLength: availableLengths.first ?? 0,
                                        existingState: state)
        }
        
        return lengthStatePANLength(numberOfDigits,
                                    availableLengths: availableLengths,
                                    existingState: state)
    }
    
    private static func lengthStatePANLength(_ numberOfDigits : Int,
                                             availableLengths : [Int],
                                             existingState    : PANLengthState) -> PANLengthState
    {
        var state = existingState
        let numberOfLengths = availableLengths.count
        var previousLength = 0
        
        for (index, panLength) in availableLengths.enumerated()
        {
            if ((index + 1) == numberOfLengths) && (numberOfDigits > previousLength)
            {
                state.insert(.isLast)
            }
            
            previousLength = panLength
            
            if numberOfDigits > panLength
            {
                if state.contains(.isLast)
                {
                    state.insert(.isLongerThanFull)
                }
                continue
            }
            
            if panLength == numberOfDigits
            {
                state.insert(.isFull)
                return state
            }
        }
        
        return state
    }
    
    private static func lengthStatePANLength(_ numberOfDigits : Int,
                                             availableLength  : Int,
                                             existingState    : PANLengthState) -> PANLengthState
    {
        var state = existingState
        state.insert(.isLast)
        
        if numberOfDigits == availableLength
        {
            state.insert(.isFull)
        }
        else if ( numberOfDigits > availableLength )
        {
            state.insert(.isLongerThanFull)
        }
        return state
    }
    
    static func validLuhn(forDigits digits: String) -> Bool
    {
        let doubleDigitSumMapping = [0,2,4,6,8,1,3,5,7,9]
        let options : NSString.EnumerationOptions = [.reverse, .byComposedCharacterSequences]
        var sum = 0
        var numberDigit = 0
        var isOdd = true
        
        let wholeString = digits.startIndex..<digits.endIndex
        digits.enumerateSubstrings(in: wholeString, options: options)
        {
            (substring, substringRange, enclosingRange, stop) in
            
            numberDigit = Int(substring ?? "") ?? 0
            sum        += isOdd ? numberDigit : doubleDigitSumMapping[numberDigit]
            isOdd       = !isOdd
        }
        
        return ((sum % 10) == 0)
    }

    struct Default
    {
        static let PANLength = 16
    }
}

struct PANLengthState: OptionSet
{    
    let rawValue: Int
    
    static let isLast           = PANLengthState(rawValue: 1 << 0)
    static let isFull           = PANLengthState(rawValue: 1 << 1)
    static let isLongerThanFull = PANLengthState(rawValue: 1 << 2)
    static let isValid          = PANLengthState(rawValue: 1 << 3)
    
}
