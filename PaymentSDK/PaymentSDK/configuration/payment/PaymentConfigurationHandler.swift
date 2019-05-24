import Foundation
import PassKit

struct PaymentConfigurationHandler
{
    public typealias Completion = (PaymentAuthorizationHandler?)->()
    
    static func getCards() -> [CardDescription]{
        let visaOneDigitRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths:[16], label: "Visa")
        let amexTwoDigitRange = BINRange(start: 37, end: 37, digitsCount: 2, PANLengths: [15])
        let amexTwoDigitRange_1 = BINRange(start: 34, end: 34, digitsCount: 2, PANLengths: [15])
        let masterTwoDigitRange = BINRange(start: 51, end: 55, digitsCount: 2, PANLengths: [16])
        let masterFourDigitRange = BINRange(start: 2221, end: 2720, digitsCount: 4, PANLengths: [16])
        let jcbFourDigitRange = BINRange(start: 3528, end: 3589, digitsCount: 4, PANLengths: [16])
        
        
        let discoverFourDigitRange = BINRange(start: 6011, end: 6011, digitsCount: 4, PANLengths: [16])
        let discoverSixDigitRange = BINRange(start: 622126, end: 622925, digitsCount: 6, PANLengths: [16])
        let discoverThreeDigitRange = BINRange(start: 644, end: 649, digitsCount: 3, PANLengths: [16])
        let discoverTwoDigitRange = BINRange(start: 65, end: 65, digitsCount: 2, PANLengths: [16])
        
        let dinersTwoDigitRange = BINRange(start: 36, end: 36, digitsCount: 2,PANLengths: [14])
        
        let visa = CardDescription(CVV                  : CardDescription.CVV(location: .back,
                                                                              length: 3,
                                                                              image:"card_bg_back_generic"),
                                   ranges               : [visaOneDigitRange],
                                   lengthSortedRanges   : [1 : [visaOneDigitRange]],
                                   image                : "visa_card_front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        
        let amex = CardDescription(CVV                  : CardDescription.CVV(location: .front,
                                                                              length: 4,
                                                                              image:"card_bg_front_cvv_amex"),
                                   ranges               : [amexTwoDigitRange, amexTwoDigitRange_1],
                                   lengthSortedRanges   : [2 : [amexTwoDigitRange, amexTwoDigitRange_1]],
                                   image                : "amex_card_front",
                                   cardType             : CardType.AMERICAN_EXPRESS,
                                   network              : .amex)
        
        let masterCard = CardDescription(CVV                  : CardDescription.CVV(location: .back,
                                                                                    length: 3,
                                                                                    image:"card_bg_back_generic"),
                                         ranges               : [masterTwoDigitRange, masterFourDigitRange],
                                         lengthSortedRanges   : [2 : [masterTwoDigitRange], 4: [masterFourDigitRange]],
                                         image                : "mc_card_front",
                                         cardType             : CardType.MASTERCARD,
                                         network              : .masterCard)
        
        let jcbCard = CardDescription(CVV                  : CardDescription.CVV(location: .back,
                                                                                 length: 3,
                                                                                 image:"card_bg_back_generic"),
                                      ranges               : [jcbFourDigitRange],
                                      lengthSortedRanges   : [4 : [jcbFourDigitRange]],
                                      image                : "jcb_card_front",
                                      cardType             : CardType.JCB,
                                      network              : .JCB)
        
        
        
        let discoverCard = CardDescription(CVV                  : CardDescription.CVV(location: .back,
                                                                                      length: 3,
                                                                                      image:"card_bg_back_generic"),
                                           ranges               : [discoverTwoDigitRange, discoverThreeDigitRange, discoverFourDigitRange, discoverSixDigitRange],
                                           lengthSortedRanges   : [2: [discoverTwoDigitRange], 3: [discoverThreeDigitRange], 4: [discoverFourDigitRange], 6: [discoverSixDigitRange]],
                                           image                : "discover_card_front",
                                           cardType             : CardType.DISCOVER,
                                           network              : .discover)
        
        
        let dinersCard = CardDescription(CVV                  : CardDescription.CVV(location: .back,
                                                                                      length: 3,
                                                                                      image:"card_bg_back_generic"),
                                           ranges               : [dinersTwoDigitRange],
                                           lengthSortedRanges   : [2: [dinersTwoDigitRange]],
                                           image                : "diners_card_front",
                                           cardType             : CardType.DINERS_CLUB_INTERNATIONAL,
                                           network              : .masterCard)
        
        return [visa, amex, masterCard, jcbCard, discoverCard, dinersCard]
    }
    
    static func configure(with completion : Completion)
    {
        completion(PaymentAuthorizationHandler(acceptedCards: getCards()))
    }
}


