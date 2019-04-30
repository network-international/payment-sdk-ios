import XCTest
@testable import PaymentSDK
import PassKit

final class CardholderFieldDelegateTestsPaymentDelegate : PaymentDelegate
{
    func beginAuthorization(didSelect paymentMethod: PaymentMethod, handler completion: @escaping (PaymentAuthorizationLink?) -> Void) {
        log("")
    }
    
    func authorizationStarted() {
        log("")
    }
    
    func authorizationCompleted(withStatus status: AuthorizationStatus) {
        log("")
    }
    
    func paymentStarted() {
        log("")
    }
    
    func paymentCompleted(with status: PaymentStatus) {
        log("")
    }
    
    
}


class CardholderFieldDelegateTests: XCTestCase
{

    class func field() -> CardFormField
    {
        return CardFormField(frame: .zero, kind: .holderName, layoutDirection:.leftToRight, actionOnDeleteEmptyField: nil)
    }
    
    class func manager() -> CardDataCollectionManager
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths:[16], label: "Visa")
        let amexRange = BINRange(start: 37, end: 37, digitsCount: 2, PANLengths: [15])
        let amexRange1 = BINRange(start: 34, end: 34, digitsCount: 2, PANLengths: [15])
        
        let card0 = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                    ranges               : [visaRange],
                                    lengthSortedRanges   : [1 : [visaRange]], image : "front",
                                    cardType             : CardType.VISA,
                                    network              : .visa)
        
        let card1 = CardDescription(CVV                  : CardDescription.CVV(location: .front, length: 4, image:"CVV-img"),
                                    ranges               : [amexRange, amexRange1],
                                    lengthSortedRanges   : [2 : [amexRange, amexRange1]], image : "front",
                                    cardType             : CardType.AMERICAN_EXPRESS,
                                    network              : .amex)
        
        let acceptedCards : [CardDescription] = [card0,card1]
        
        let delegate = CardPANFieldDelegateTestsPaymentDelegate()
        
        return CardDataCollectionManager(withDelegate: delegate,
                                         acceptedCards: acceptedCards)
    }
    
    
    // MARK: - Validation Initial -
    
    func test_00()
    {
        let field = type(of: self).field()
        field.textField.text = ""
        let delegate = CardholderFieldDelegate(withTextField  : field,
                                               layoutDirection: .leftToRight,
                                               manager        : type(of: self).manager())
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and empty field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and empty field text.")
        }
    }
    
    // MARK: - Validation Final -
    
    func test_finalContext_00()
    {
        let field = type(of: self).field()
        field.textField.text = ""
        let delegate = CardholderFieldDelegate(withTextField  : field,
                                               layoutDirection: .leftToRight,
                                               manager        : type(of: self).manager())
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .cardHolder,
                                              "Should be invalid for final context and empty field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and empty field text.")
        }
    }
    
    func test_finalContext_01()
    {
        let field = type(of: self).field()
        field.textField.text = "VALID NAME"
        let delegate = CardholderFieldDelegate(withTextField  : field,
                                               layoutDirection: .leftToRight,
                                               manager        : type(of: self).manager())
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for final context and valid field text.")
        default     : XCTAssert(false ,
                                "Should be valid for final context and valid field text.")
        }
    }
    
    func test_finalContext_02()
    {
        let field = type(of: self).field()
        field.textField.text = "INVALID NAME DUE TO BEING WAY TOO LONG FOR A CARD"
        let delegate = CardholderFieldDelegate(withTextField  : field,
                                               layoutDirection: .leftToRight,
                                               manager        : type(of: self).manager())
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .cardHolder,
                                              "Should be invalid for final context and invalid field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and invalid field text.")
        }
    }

}
