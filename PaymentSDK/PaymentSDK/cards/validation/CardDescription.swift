import Foundation
import PassKit

struct CardDescription
{
    let CVV                 : CVV
    let ranges              : [BINRange]
    let lengthSortedRanges  : [Int:[BINRange]]
    let network             : PKPaymentNetwork
    let type                : PKPaymentMethodType
    let image               : String?
    let displayName         : String?
    let cardType            : CardType?
    
    init(CVV                  : CVV,
         ranges               : [BINRange],
         lengthSortedRanges   : [Int:[BINRange]],
         image                : String?,
         cardType             : CardType?,
         network              : PKPaymentNetwork)
    {
        self.CVV = CVV
        self.ranges = ranges
        self.lengthSortedRanges = lengthSortedRanges
        self.network = network
        self.type = .unknown
        self.image = image
        self.displayName = nil
        self.cardType = cardType
    }
    
    init(CVV                 : CVV,
         ranges              : [BINRange],
         lengthSortedRanges  : [Int:[BINRange]],
         network             : PKPaymentNetwork,
         type                : PKPaymentMethodType,
         image               : String?,
         displayName         : String?,
         cardType            : CardType?)
    {
        self.CVV = CVV
        self.ranges = ranges
        self.lengthSortedRanges = lengthSortedRanges
        self.network = network
        self.type = type
        self.image = image
        self.displayName = displayName
        self.cardType = cardType
    }
    
    struct CVV
    {
        let location : Location
        let length   : Int
        let image    : String?
        
        enum Location
        {
            case front
            case back
        }
    }
}


public enum CardType : String{
    case VISA
    case MASTERCARD
    case AMERICAN_EXPRESS
    case JCB
    case DISCOVER
    case DINERS_CLUB_INTERNATIONAL
}
