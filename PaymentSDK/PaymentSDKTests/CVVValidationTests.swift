import XCTest
@testable import PaymentSDK

class CVVValidationTests: XCTestCase
{
    func test_00()
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange],
                                   lengthSortedRanges   : [1 : [visaRange]],
                                   image                : "visa_card_front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        let max = CVVValidation.maxLengthCVV(forCard: card)
        XCTAssert( max == 3,
                   "The CVV should be of max length 3.")
    }
    
    func test_01()
    {
        let american0 = BINRange(start: 3777, end: 3799, digitsCount: 4, PANLengths: [15])
        let american1 = BINRange(start: 38, end: 38, digitsCount: 2, PANLengths: [15])
        
        let card =  CardDescription(CVV                  : CardDescription.CVV(location: .front, length: 4, image:"CVV-img"),
                                    ranges               : [american0, american1],
                                    lengthSortedRanges   : [2 : [american1], 4 : [american0]],
                                    image                : "visa_card_front",
                                    cardType             : CardType.AMERICAN_EXPRESS,
                                    network              : .amex)
        let max = CVVValidation.maxLengthCVV(forCard: card)
        XCTAssert( max == 4,
                   "The CVV should be of max length 4.")
    }
    
    func test_02()
    {
        let max = CVVValidation.maxLengthCVV(forCard: nil)
        XCTAssert( max == 3,
                   "The default CVV should be of max length 3.")
    }
}
