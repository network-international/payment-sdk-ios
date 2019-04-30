import Foundation

struct DateUtility
{
    static func currentDate() -> CardDate
    {
        let units : Set<Calendar.Component> =  [.month, .year]
        let components = NSCalendar.current.dateComponents(units, from: Date())
        let month = components.month ?? 01
        let year  = components.year  ?? 1900
        
        return CardDate(month: CardDate.Month(rawValue: month) ?? .Jan,
                        year: year,
                        kind: nil)
    }
    
    static func currentCentury() -> Int
    {
        return calculateCenturyOnce
    }
}


// thread safely executed once only
private let calculateCenturyOnce : Int =
{
    let units : Set<Calendar.Component> =  [.year]
    let components = NSCalendar.current.dateComponents(units, from: Date())
    let year  = components.year  ?? 1900
    let century = (year / 100) * 100
    
    return century
}()
