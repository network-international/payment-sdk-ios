import Foundation

struct CardIdentity
{
    let PAN             : String
    let description     : CardDescription?
    let matchingRanges  : [BINRange]?
    let certainty       : MatchCertainty
    let availability    : Availability

    enum MatchCertainty
    {
        case none
        case probable
        case match
    }
    
    enum Availability
    {
        case notAvailable
        case available
    }
}
