import XCTest
@testable import PaymentSDK

class PANValidationTests: XCTestCase
{
    func test_00()
    {
        let PAN = "4111111111111111"
        XCTAssert(PANValidation.validLuhn(forDigits: PAN),
                  "The PAN should be valid.")
    }
    
    func test_01()
    {
        let PAN = "4111111111111110"
        XCTAssert(PANValidation.validLuhn(forDigits: PAN) == false,
                  "The PAN should be not valid.")
    }
    
    func test_02()
    {
        let PAN = "377777777777771"
        XCTAssert(PANValidation.validLuhn(forDigits: PAN) == false,
                  "The PAN should be not valid.")
    }
    
    func test_03()
    {
        let PAN = "377777777777770"
        XCTAssert(PANValidation.validLuhn(forDigits: PAN),
                  "The PAN should be valid.")
    }

    func test_04()
    {
        let PAN = "4119"
        XCTAssert(PANValidation.validLuhn(forDigits: PAN),
                  "The PAN should be valid.")
    }
    
    func test_05()
    {
        let PAN = "4118"
        XCTAssert(PANValidation.validLuhn(forDigits: PAN) == false,
                  "The PAN should be not valid.")
    }
    
    func test_005()
    {
        let PAN = "4111111111111111"
        let state = PANValidation.lengthStatePAN(PAN,
                                                 cardIdentity: nil)
        XCTAssert(state.rawValue == 0,
                  "The state should be 0.")
    }
    
    func test_006()
    {
        let PAN = "4111111111111111"
        let identity = CardIdentity(PAN             : PAN,
                                    description     : nil,
                                    matchingRanges  : nil,
                                    certainty       : .probable,
                                    availability    : .available)
        let state = PANValidation.lengthStatePAN(PAN,
                                                 cardIdentity: identity)
        XCTAssert(state.contains(.isFull),
                  "The state should contain isFull.")
        XCTAssert(state.contains(.isValid) == false,
                  "The state should not contain isValid as there is no description.")
        XCTAssert(state.contains(.isLongerThanFull) == false,
                  "The state should not contain isLongerThanFull as there is a 19 length option for this range.")
    }
    
    func test_007()
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let description = CardDescription(CVV: CardDescription.CVV(location: .back,
                                                                   length: 3, image:"CVV-img"),
                                          ranges: [visaRange],
                                          lengthSortedRanges: [1:[visaRange]], image : "front",
                                          cardType             : CardType.VISA,
                                          network              : .visa)
        let PAN = "4111111111111111"
        let identity = CardIdentity(PAN             : PAN,
                                    description     : description,
                                    matchingRanges  : nil,
                                    certainty       : .none,
                                    availability    : .available)
        let state = PANValidation.lengthStatePAN(PAN,
                                                 cardIdentity: identity)
        XCTAssert(state.contains(.isFull),
                  "The state should contain isFull.")
        XCTAssert(state.contains(.isValid) == false,
                  "The state should not contain isValid as there is no description.")
        XCTAssert(state.contains(.isLongerThanFull) == false,
                  "The state should not contain isLongerThanFull as there is a 19 length option for this range.")
    }
    
    func test_06()
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange],
                                   lengthSortedRanges   : [1 : [visaRange]], image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        let PAN = "4118"
        let identity = CardDetector.cardIdentity(forBIN: PAN,
                                                 acceptedCards: [card])
        let state = PANValidation.lengthStatePAN(PAN,
                                                 cardIdentity: identity)
        XCTAssert(state.rawValue == 0,
                  "The state should be 0.")
    }
    
    func test_07()
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange],
                                   lengthSortedRanges   : [1 : [visaRange]], image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        let PAN = "4111111111111111"
        let identity = CardDetector.cardIdentity(forBIN: PAN,
                                                 acceptedCards: [card])
        let state = PANValidation.lengthStatePAN(PAN,
                                                 cardIdentity: identity)
        XCTAssert(state.contains(.isFull),
                  "The state should contain isFull.")
        XCTAssert(state.contains(.isValid),
                  "The state should contain isValid.")
        XCTAssert(state.contains(.isLast) == false,
                  "The state should not contain isLast as there is a 19 length option for this range.")
        XCTAssert(state.contains(.isLongerThanFull) == false,
                  "The state should not contain isLongerThanFull as there is a 19 length option for this range.")
    }
    
    func test_08()
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange],
                                   lengthSortedRanges   : [1 : [visaRange]], image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        let PAN = "4111111111111110"
        let identity = CardDetector.cardIdentity(forBIN: PAN,
                                                 acceptedCards: [card])
        let state = PANValidation.lengthStatePAN(PAN,
                                                 cardIdentity: identity)
        XCTAssert(state.contains(.isFull),
                  "The state should contain isFull.")
        XCTAssert(state.contains(.isValid) == false,
                  "The state should not contain isValid if the Luhn algorithm returns false.")
        XCTAssert(state.contains(.isLast) == false,
                  "The state should not contain isLast as there is a 19 length option for this range.")
        XCTAssert(state.contains(.isLongerThanFull) == false,
                  "The state should not contain isLongerThanFull as there is a 19 length option for this range.")
    }
    
    func test_09()
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange],
                                   lengthSortedRanges   : [1 : [visaRange]], image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        let PAN = "4111111111111111227"
        let identity = CardDetector.cardIdentity(forBIN: PAN,
                                                 acceptedCards: [card])
        let state = PANValidation.lengthStatePAN(PAN,
                                                 cardIdentity: identity)
        XCTAssert(state.contains(.isFull),
                  "The state should contain isFull.")
        XCTAssert(state.contains(.isValid),
                  "The state should contain isValid.")
        XCTAssert(state.contains(.isLast),
                  "The state should contain isLast.")
        XCTAssert(state.contains(.isLongerThanFull) == false,
                  "The state should not contain isLongerThanFull as there is a 19 length option for this range.")
    }
    
    func test_10()
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange],
                                   lengthSortedRanges   : [1 : [visaRange]], image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        let PAN = "41111111111111112278"
        let identity = CardDetector.cardIdentity(forBIN: PAN,
                                                 acceptedCards: [card])
        let state = PANValidation.lengthStatePAN(PAN,
                                                 cardIdentity: identity)
        XCTAssert(state.contains(.isFull) == false,
                  "The state should not contain isFull as the length is longer than full.")
        XCTAssert(state.contains(.isValid) == false,
                  "The state should not contain isValid.")
        XCTAssert(state.contains(.isLast),
                  "The state should contain isLast.")
        XCTAssert(state.contains(.isLongerThanFull),
                  "The state should contain isLongerThanFull.")
    }
    
    func test_14()
    {
        let max = PANValidation.maxLengthsPAN(forCard: nil)
        XCTAssert( max.first! == 16,
                   "The default max PAN length should be 16.")
    }
    
    func test_15()
    {
        let identity = CardDetector.cardIdentity(forBIN: "380000",
                                                 acceptedCards: [])
        let max = PANValidation.maxLengthsPAN(forCard: identity)
        XCTAssert( max.first! == 16,
                   "The default max PAN length should be 16.")
    }
    
    func test_16()
    {
        let american0 = CardDescription(CVV: CardDescription.CVV(location: .front,
                                                                 length: 4, image:"CVV-img"),
                                        ranges: [],
                                        lengthSortedRanges: [:], image : "front",
                                        cardType             : CardType.AMERICAN_EXPRESS,
                                        network              : .amex)
        let identity = CardIdentity(PAN             : "411",
                                    description     : american0,
                                    matchingRanges  : nil,
                                    certainty       : .probable,
                                    availability    : .available)
        let max = PANValidation.maxLengthsPAN(forCard: identity)
        XCTAssert( max.first! == 16,
                   "The default max PAN length should be 16.")
    }
}
