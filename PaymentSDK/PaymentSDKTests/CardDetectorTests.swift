import XCTest
@testable import PaymentSDK

class CardDetectorTests: XCTestCase
{
    func test_00()
    {
        let identity = CardDetector.cardIdentity(forBIN: nil,
                                                 acceptedCards: nil)
        XCTAssert(identity.PAN == "",
                  "The PAN should be empty for a nil value passed to the method.")
        XCTAssert(identity.description == nil,
                  "The description should be nil for a nil value passed to the method.")
        XCTAssert(identity.matchingRanges == nil,
                  "The matching ranges should be nil for a nil value passed to the method.")
        XCTAssert(identity.certainty == .none,
                  "The certainty should be none for a nil value passed to the method.")
        XCTAssert(identity.availability == .notAvailable,
                  "The availability should be not available for a nil value passed to the method.")
    }
    
    func test_000()
    {
        let identity = CardDetector.cardIdentity(forBIN: "45",
                                                 acceptedCards: nil)
        XCTAssert(identity.PAN == "45",
                  "The PAN should be 45.")
        XCTAssert(identity.description == nil,
                  "The description should be nil for a nil value passed to the method.")
        XCTAssert(identity.matchingRanges == nil,
                  "The matching ranges should be nil for a nil value passed to the method.")
        XCTAssert(identity.certainty == .none,
                  "The certainty should be none for a nil value passed to the method.")
        XCTAssert(identity.availability == .notAvailable,
                  "The availability should be not available for a nil value passed to the method.")
    }
    
    func test_01()
    {
        let identity = CardDetector.cardIdentity(forBIN: "",
                                                 acceptedCards: [])
        XCTAssert(identity.PAN == "",
                  "The PAN should be empty for an empty value passed to the method.")
        XCTAssert(identity.description == nil,
                  "The description should be nil for an empty value passed to the method.")
        XCTAssert(identity.matchingRanges == nil,
                  "The matching ranges should be nil for an empty value passed to the method.")
        XCTAssert(identity.certainty == .none,
                  "The certainty should be none for an empty value passed to the method.")
        XCTAssert(identity.availability == .notAvailable,
                  "The availability should be not available for an empty value passed to the method.")
    }
    
    func test_02()
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange],
                                   lengthSortedRanges   : [1 : [visaRange]],
                                   image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        
        let identity = CardDetector.cardIdentity(forBIN: "4",
                                                 acceptedCards: [card])
        XCTAssert(identity.PAN == "4",
                  "The PAN should be 4.")
        XCTAssert(identity.description != nil,
                  "The description should not be nil.")
        XCTAssert(identity.matchingRanges != nil,
                  "The matching ranges should not be nil.")
        XCTAssert(identity.matchingRanges!.count == 1,
                  "The matching ranges should contain 1 element.")
        XCTAssert(identity.matchingRanges!.first! == visaRange,
                  "The matching ranges should be equal to the passed in one.")
        XCTAssert(identity.certainty == .probable,
                  "The certainty should be probable for an empty value passed to the method.")
        XCTAssert(identity.availability == .available,
                  "The availability should be available for an empty value passed to the method.")
    }
    
    func test_03()
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange],
                                   lengthSortedRanges   : [1 : [visaRange]],
                                   image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        
        let identity = CardDetector.cardIdentity(forBIN: "5",
                                                 acceptedCards: [card])
        XCTAssert(identity.PAN == "5",
                  "The PAN should be 5.")
        XCTAssert(identity.description == nil,
                  "The description should be nil for a BIN with no match passed to the method.")
        XCTAssert(identity.matchingRanges == nil,
                  "The matching ranges should be nil for a BIN with no match passed to the method.")
        XCTAssert(identity.certainty == .none,
                  "The certainty should be none for a BIN with no match passed to the method.")
        XCTAssert(identity.availability == .notAvailable,
                  "The availability should be not available for a BIN with no match passed to the method.")
    }
    
    func test_04()
    {
        let visaRange0 = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let visaRange1 = BINRange(start: 4356, end: 4999, digitsCount: 4, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange0, visaRange1],
                                   lengthSortedRanges   : [1 : [visaRange0], 4 : [visaRange1]],
                                   image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        
        let identity = CardDetector.cardIdentity(forBIN: "4357",
                                                 acceptedCards: [card])
        XCTAssert(identity.PAN == "4357",
                  "The PAN should be 4357.")
        XCTAssert(identity.description != nil,
                  "The description should not be nil.")
        XCTAssert(identity.matchingRanges != nil,
                  "The matching ranges should not be nil.")
        XCTAssert(identity.matchingRanges!.count == 1,
                  "The matching ranges should contain 1 element.")
        XCTAssert(identity.matchingRanges!.first! == visaRange1,
                  "The matching ranges should be equal to the passed in one.")
        XCTAssert(identity.certainty == .probable,
                  "The certainty should be probable for an empty value passed to the method.")
        XCTAssert(identity.availability == .available,
                  "The availability should be available for an empty value passed to the method.")
    }
    
    func test_05()
    {
        let visaRange0 = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let visaRange1 = BINRange(start: 4356, end: 4999, digitsCount: 4, PANLengths: [16,19])
        let card = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange0, visaRange1],
                                   lengthSortedRanges   : [1 : [visaRange0], 4 : [visaRange1]],
                                   image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        
        let identity = CardDetector.cardIdentity(forBIN: "435700",
                                                 acceptedCards: [card])
        XCTAssert(identity.PAN == "435700",
                  "The PAN should be 435700.")
        XCTAssert(identity.description != nil,
                  "The description should not be nil.")
        XCTAssert(identity.matchingRanges != nil,
                  "The matching ranges should not be nil.")
        XCTAssert(identity.matchingRanges!.count == 1,
                  "The matching ranges should contain 1 element.")
        XCTAssert(identity.matchingRanges!.first! == visaRange1,
                  "The matching ranges should be equal to the passed in one.")
        XCTAssert(identity.certainty == .match,
                  "The certainty should be match for an empty value passed to the method.")
        XCTAssert(identity.availability == .available,
                  "The availability should be available for an empty value passed to the method.")
    }
    
    func test_06()
    {
        let visaRange0 = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let visaRange1 = BINRange(start: 4356, end: 4999, digitsCount: 4, PANLengths: [16,19])
        
        let american0 = BINRange(start: 3777, end: 3799, digitsCount: 4, PANLengths: [15])
        let american1 = BINRange(start: 38, end: 38, digitsCount: 2, PANLengths: [15])
        
        let card0 = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                   ranges               : [visaRange0, visaRange1],
                                   lengthSortedRanges   : [1 : [visaRange0], 4 : [visaRange1]],
                                   image : "front",
                                   cardType             : CardType.VISA,
                                   network              : .visa)
        
        let card1 = CardDescription(CVV                  : CardDescription.CVV(location: .front, length: 4, image:"CVV-img"),
                                   ranges               : [american0, american1],
                                   lengthSortedRanges   : [2 : [american1], 4 : [american0]],
                                   image : "front",
                                   cardType             : CardType.AMERICAN_EXPRESS,
                                   network              : .amex)
        
        let identity = CardDetector.cardIdentity(forBIN: "435700",
                                                 acceptedCards: [card0, card1])
        XCTAssert(identity.PAN == "435700",
                  "The PAN should be 435700.")
        XCTAssert(identity.description != nil,
                  "The description should not be nil.")
        XCTAssert(identity.matchingRanges != nil,
                  "The matching ranges should not be nil.")
        XCTAssert(identity.matchingRanges!.count == 1,
                  "The matching ranges should contain 1 element.")
        XCTAssert(identity.matchingRanges!.first! == visaRange1,
                  "The matching ranges should be equal to the passed in one.")
        XCTAssert(identity.certainty == .match,
                  "The certainty should be match for an empty value passed to the method.")
        XCTAssert(identity.availability == .available,
                  "The availability should be available for an empty value passed to the method.")
    }
    
    func test_07()
    {
        let visaRange0 = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let visaRange1 = BINRange(start: 4356, end: 4999, digitsCount: 4, PANLengths: [16,19])
        
        let american0 = BINRange(start: 3777, end: 3799, digitsCount: 4, PANLengths: [15])
        let american1 = BINRange(start: 38, end: 38, digitsCount: 2, PANLengths: [15])
        
        let card0 = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                    ranges               : [visaRange0, visaRange1],
                                    lengthSortedRanges   : [1 : [visaRange0], 4 : [visaRange1]],
                                    image : "front",
                                    cardType             : CardType.VISA,
                                    network              : .visa)
        
        let card1 = CardDescription(CVV                  : CardDescription.CVV(location: .front, length: 4, image:"CVV-img"),
                                    ranges               : [american0, american1],
                                    lengthSortedRanges   : [2 : [american1], 4 : [american0]],
                                    image : "front",
                                    cardType             : CardType.AMERICAN_EXPRESS,
                                    network              : .amex)
        
        let identity = CardDetector.cardIdentity(forBIN: "3777",
                                                 acceptedCards: [card0, card1])
        XCTAssert(identity.PAN == "3777",
                  "The PAN should be 3777.")
        XCTAssert(identity.description != nil,
                  "The description should not be nil.")
        XCTAssert(identity.matchingRanges != nil,
                  "The matching ranges should not be nil.")
        XCTAssert(identity.matchingRanges!.count == 1,
                  "The matching ranges should contain 1 element.")
        XCTAssert(identity.matchingRanges!.first! == american0,
                  "The matching ranges should be equal to the passed in one.")
        XCTAssert(identity.certainty == .probable,
                  "The certainty should be probable for an empty value passed to the method.")
        XCTAssert(identity.availability == .available,
                  "The availability should be available for an empty value passed to the method.")
    }
    
    func test_08()
    {
        let visaRange0 = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths: [16,19])
        let visaRange1 = BINRange(start: 4356, end: 4999, digitsCount: 4, PANLengths: [16,19])
        
        let american0 = BINRange(start: 3777, end: 3799, digitsCount: 4, PANLengths: [15])
        let american1 = BINRange(start: 38, end: 38, digitsCount: 2, PANLengths: [15])
        
        let card0 = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                    ranges               : [visaRange0, visaRange1],
                                    lengthSortedRanges   : [1 : [visaRange0], 4 : [visaRange1]],
                                    image : "front",
                                    cardType             : CardType.VISA,
                                    network              : .visa)
        
        let card1 = CardDescription(CVV                  : CardDescription.CVV(location: .front, length: 4, image:"CVV-img"),
                                    ranges               : [american0, american1],
                                    lengthSortedRanges   : [2 : [american1], 4 : [american0]],
                                    image : "front",
                                    cardType             : CardType.AMERICAN_EXPRESS,
                                    network              : .amex)
        
        let identity = CardDetector.cardIdentity(forBIN: "380000",
                                                 acceptedCards: [card0, card1])
        XCTAssert(identity.PAN == "380000",
                  "The PAN should be 380000.")
        XCTAssert(identity.description != nil,
                  "The description should not be nil.")
        XCTAssert(identity.matchingRanges != nil,
                  "The matching ranges should not be nil.")
        XCTAssert(identity.matchingRanges!.count == 1,
                  "The matching ranges should contain 1 element.")
        XCTAssert(identity.matchingRanges!.first! == american1,
                  "The matching ranges should be equal to the passed in one.")
        XCTAssert(identity.certainty == .match,
                  "The certainty should be match for an empty value passed to the method.")
        XCTAssert(identity.availability == .available,
                  "The availability should be available for an empty value passed to the method.")
    }

}
