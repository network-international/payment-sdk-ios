import Foundation

struct CVVValidation
{
    static func maxLengthCVV(forCard card: CardDescription?) -> Int
    {
        guard let cardDescription = card else { return Default.CVVLength }
        return cardDescription.CVV.length
    }
    
    struct Default
    {
        static let CVVLength = 3
    }
}
