import Foundation

struct CardDate
{
    let month : Month
    let year  : Int
    let kind  : Kind?

    enum Month : Int
    {
        case Jan = 1, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec
    }
    
    enum Kind
    {
        case start
        case expiry
    }
    
    static func veryOldExpiryDate() -> CardDate
    {
        return CardDate(month: .Jan, year: 1900, kind: .expiry)
    }
}
