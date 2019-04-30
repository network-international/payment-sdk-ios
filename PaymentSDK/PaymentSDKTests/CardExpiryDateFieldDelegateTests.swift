import XCTest
@testable import PaymentSDK
import PassKit

final class CardExpiryDateFieldDelegateTestsPaymentDelegate : PaymentDelegate
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


class CardExpiryDateFieldDelegateTests: XCTestCase
{
    class func field() -> CardFormField
    {
        return CardFormField(frame: .zero, kind: .expiryDate, layoutDirection:.leftToRight, actionOnDeleteEmptyField: nil)
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
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and empty field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and empty field text.")
        }
    }
    
    func test_01()
    {
        let field = type(of: self).field()
        field.textField.text = nil
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and nil field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and nil field text.")
        }
    }
    
    func test_02()
    {
        let field = type(of: self).field()
        field.textField.text = "13"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .endDate,
                                              "Should be invalid for initial context and invalid date in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for initial context and invalid date in field text.")
        }
    }
    
    func test_03()
    {
        let field = type(of: self).field()
        field.textField.text = "13/01"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .endDate,
                                              "Should be invalid for initial context and invalid date in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for initial context and invalid date in field text.")
        }
    }
    
    func test_04()
    {
        let field = type(of: self).field()
        field.textField.text = "12/33"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and valid date in field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and valid date in field text.")
        }
    }
    
    func test_05()
    {
        let field = type(of: self).field()
        field.textField.text = "1233"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and valid date in field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and valid date in field text.")
        }
    }
    
    func test_06()
    {
        let field = type(of: self).field()
        field.textField.text = "12/3"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and valid date in field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and valid date in field text.")
        }
    }
    
    // MARK: - Validation Final -
    
    func test_finalContext_00()
    {
        let field = type(of: self).field()
        field.textField.text = ""
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .endDate,
                                              "Should be invalid for final context and empty field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and empty field text.")
        }
    }
    
    func test_finalContext_01()
    {
        let field = type(of: self).field()
        field.textField.text = nil
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .final)
        
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .endDate,
                                              "Should be invalid for final context and nil field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and nil field text.")
        }
    }
    
    func test_finalContext_02()
    {
        let field = type(of: self).field()
        field.textField.text = "13"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .endDate,
                                              "Should be invalid for initial context and invalid date in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for initial context and invalid date in field text.")
        }
    }
    
    func test_finalContext_03()
    {
        let field = type(of: self).field()
        field.textField.text = "13/01"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .endDate,
                                              "Should be invalid for initial context and invalid date in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for initial context and invalid date in field text.")
        }
    }
    
    func test_finalContext_04()
    {
        let field = type(of: self).field()
        field.textField.text = "12/33"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and valid date in field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and valid date in field text.")
        }
    }
    
    func test_finalContext_05()
    {
        let field = type(of: self).field()
        field.textField.text = "1233"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and valid date in field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and valid date in field text.")
        }
    }
    
    func test_finalContext_06()
    {
        let field = type(of: self).field()
        field.textField.text = "12/3"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .endDate,
                                              "Should be invalid for initial context and invalid date in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for initial context and invalid date in field text.")
        }
    }
    
    func test_finalContext_07()
    {
        let field = type(of: self).field()
        field.textField.text = "9"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .endDate,
                                              "Should be invalid for initial context and invalid date in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for initial context and invalid date in field text.")
        }
    }
    
    func test_finalContext_08()
    {
        let field = type(of: self).field()
        field.textField.text = "11"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardExpiryDateFieldDelegate(withTextField  : field,
                                                   layoutDirection: .leftToRight,
                                                   manager        : type(of: self).manager(),
                                                   focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits("423456")
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .endDate,
                                              "Should be invalid for initial context and invalid date in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for initial context and invalid date in field text.")
        }
    }
    
}
