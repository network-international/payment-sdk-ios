import Foundation

struct CardDetector
{
    static func cardIdentity(forBIN BIN: String?, acceptedCards: [CardDescription]?) -> CardIdentity
    {
        guard let validBIN = BIN, validBIN.count > 0 else { return self.identityForInvalidBIN(BIN) }
        guard let availableCards = acceptedCards, availableCards.count > 0 else
        {
            return self.identityForInvalidBIN(validBIN)
        }
        
        let matches = self.matchingRanges(forBIN: validBIN, acceptedCards: availableCards)
        guard let matchingCard = matches.firstMatch, let ranges = matches.matchingRanges else
        {
            return self.identityForInvalidBIN(validBIN)
        }
        
        let certianty = self.certainty(forCard: matchingCard, BINLength: validBIN.count)
        
        return CardIdentity(PAN             : validBIN,
                            description     : matchingCard,
                            matchingRanges  : ranges,
                            certainty       : certianty,
                            availability    : .available)
    }
    
    private static func identityForInvalidBIN(_ BIN: String?) -> CardIdentity
    {
        return CardIdentity(PAN             : BIN ?? "",
                            description     : nil,
                            matchingRanges  : nil,
                            certainty       : .none,
                            availability    : .notAvailable)
    }
    
    static func certainty(forCard matchingCard: CardDescription, BINLength: Int) -> CardIdentity.MatchCertainty
    {
        if BINLength >= 6 { return .match }
        return .probable
    }

    private static func matchingRanges(forBIN BIN: String,
                                       acceptedCards: [CardDescription]) -> (firstMatch: CardDescription?,
                                                                             matchingRanges: [BINRange]?)
    {
        let length = BIN.count
        var lengthSortedRanges : [Int:[BINRange]] = [:]
        
        for card in acceptedCards
        {
            lengthSortedRanges = card.lengthSortedRanges
            guard let ranges = lengthSortedRanges[length] else { continue }
            if let range = self.firstMatchingRange(forBIN: BIN, ranges: ranges)
            {
                return (card, [range])
            }
        }
        
        if length < 2 {
            return (nil, nil)
        }
        
        let smallerBIN = String(BIN.dropLast())
        return self.matchingRanges(forBIN: smallerBIN, acceptedCards: acceptedCards)
        
    }
    
    private static func firstMatchingRange(forBIN BIN: String,
                                           ranges: [BINRange]) -> BINRange?
    {
        let valueBIN = Int(BIN) ?? 0
        for range in ranges
        {
            if range.start <= valueBIN && range.end >= valueBIN
            {
                return range
            }
        }
        return nil
    }
    
}
