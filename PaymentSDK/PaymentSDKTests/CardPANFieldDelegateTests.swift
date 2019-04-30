import XCTest
@testable import PaymentSDK
import PassKit

final class CardPANFieldDelegateTestsPaymentDelegate : PaymentDelegate
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

class CardPANFieldDelegateTests: XCTestCase
{
    
    class func field() -> CardFormField
    {
        return CardFormField(frame: .zero, kind: .PAN, layoutDirection:.leftToRight, actionOnDeleteEmptyField: nil)
    }
    
    class func manager() -> CardDataCollectionManager
    {
        let visaRange = BINRange(start: 4, end: 4, digitsCount: 1, PANLengths:[16], label: "Visa")
        let amexRange = BINRange(start: 37, end: 37, digitsCount: 2, PANLengths: [15])
        let amexRange1 = BINRange(start: 34, end: 34, digitsCount: 2, PANLengths: [15])
        
        let card0 = CardDescription(CVV                  : CardDescription.CVV(location: .back, length: 3, image:"CVV-img"),
                                    ranges               : [visaRange],
                                    lengthSortedRanges   : [1 : [visaRange]],
                                    image : "front",
                                    cardType             : CardType.VISA,
                                    network              : .visa)
        
        let card1 = CardDescription(CVV                  : CardDescription.CVV(location: .front, length: 4, image:"CVV-img"),
                                    ranges               : [amexRange, amexRange1],
                                    lengthSortedRanges   : [2 : [amexRange, amexRange1]],
                                    image : "front",
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
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
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
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        
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
        field.textField.text = "4111 1111 1111 1110"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and invalid PAN in field text of correct length.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and invalid PAN in field text of correct length.")
        }
    }
    
    func test_03()
    {
        let field = type(of: self).field()
        field.textField.text = "41"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and invalid PAN in field text of shorter length.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and invalid PAN in field text of shorter length.")
        }
    }
    
    func test_04()
    {
        let field = type(of: self).field()
        field.textField.text = "1"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and invalid PAN in field text of shorter length.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and invalid PAN in field text of shorter length.")
        }
    }
    
    func test_05()
    {
        let field = type(of: self).field()
        field.textField.text = " 1 adf"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and invalid PAN in field text of shorter length.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and invalid PAN in field text of shorter length.")
        }
    }
    
    func test_06()
    {
        let field = type(of: self).field()
        field.textField.text = "4111 1111 1111 1111 1111 111"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .PAN,
                                              "Should be invalid for initial context and invalid (too long) PAN in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for initial context and invalid (too long) PAN in field text.")
        }
    }
    
    func test_07()
    {
        let field = type(of: self).field()
        field.textField.text = "4111 1111 1111 1111"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and valid PAN in field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and valid PAN in field text.")
        }
    }
    
    // MARK: - Validation Final -
    
    func test_finalContext_00()
    {
        let field = type(of: self).field()
        field.textField.text = ""
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .PAN,
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
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .PAN,
                                              "Should be invalid for final context and nil field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and nil field text.")
        }
    }
    
    func test_finalContext_02()
    {
        let field = type(of: self).field()
        field.textField.text = "4111 1111 1111 1110"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .PAN,
                                              "Should be invalid for final context and invalid PAN in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and invalid PAN in field text.")
        }
    }
    
    func test_finalContext_03()
    {
        let field = type(of: self).field()
        field.textField.text = "41"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .PAN,
                                              "Should be invalid for final context and invalid PAN in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and invalid PAN in field text.")
        }
    }
    
    func test_finalContext_04()
    {
        let field = type(of: self).field()
        field.textField.text = "1"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .PAN,
                                              "Should be invalid for final context and invalid PAN in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and invalid PAN in field text.")
        }
    }
    
    func test_finalContext_05()
    {
        let field = type(of: self).field()
        field.textField.text = " 1 adf"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .PAN,
                                              "Should be invalid for final context and invalid PAN in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and invalid PAN in field text.")
        }
    }
    
    func test_finalContext_06()
    {
        let field = type(of: self).field()
        field.textField.text = "4111 1111 1111 1111 1111 111"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .PAN,
                                              "Should be invalid for final context and invalid PAN in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and invalid PAN in field text.")
        }
    }
    
    func test_finalContext_07()
    {
        let field = type(of: self).field()
        field.textField.text = "4111 1111 1111 1111"
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial final and valid PAN in field text.")
        default     : XCTAssert(false ,
                                "Should be valid for initial final and valid PAN in field text.")
        }
    }
    
    // MARK: - Unsupported PANs -
    
    func test_unsupportedPAN_00()
    {
        let field = type(of: self).field()
        field.textField.text = "1234 1234 1234 1238" // valid luhn
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .final)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason == .PAN,
                                              "Should be invalid for final context and unsupported PAN in field text.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and unsupported PAN in field text.")
        }
    }
    
    func test_unsupportedPAN_01()
    {
        let field = type(of: self).field()
        field.textField.text = "1234 1234 1234 1238" // valid luhn
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        let delegate = CardPANFieldDelegate(withTextField  : field,
                                            layoutDirection: .leftToRight,
                                            manager        : type(of: self).manager(),
                                            focusAction    : focusAction)
        delegate.manager.updateIdentityForFirstSixDigits(field.textField.text!.firstSix())
        
        let validity = delegate.valid(inContext: .initial)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and unsupported PAN in field text of shorter length than default.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and unsupported PAN in field text of shorter length than default.")
        }
    }
    
}
