import XCTest
@testable import PaymentSDK
import PassKit

class CardNumbersFieldTests: XCTestCase
{
    class func panField() -> CardFormField
    {
        return CardFormField(frame: .zero, kind: .PAN, layoutDirection:.leftToRight, actionOnDeleteEmptyField: nil)
    }
    
    class func endDateField() -> CardFormField
    {
        return CardFormField(frame: .zero, kind: .expiryDate, layoutDirection:.leftToRight, actionOnDeleteEmptyField: nil)
    }
    
    class func cvvField() -> CardFormField
    {
        return CardFormField(frame: .zero, kind: .CVV, layoutDirection:.leftToRight, actionOnDeleteEmptyField: nil)
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
        let panField     = type(of: self).panField()
        let endDateField = type(of: self).endDateField()
        let cvvField     = type(of: self).cvvField()
        panField.textField.text     = ""
        endDateField.textField.text = ""
        cvvField.textField.text     = ""
        
        let manager = type(of: self).manager()
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        
        let panDelegate = CardPANFieldDelegate(withTextField  : panField,
                                            layoutDirection: .leftToRight,
                                            manager        : manager,
                                            focusAction    : focusAction)
        
        let dateDelegate = CardExpiryDateFieldDelegate(withTextField  : endDateField,
                                                       layoutDirection: .leftToRight,
                                                       manager        : manager,
                                                       focusAction    : focusAction)
        
        let cvvDelegate = CardCVVFieldDelegate(withTextField  : cvvField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        panDelegate.manager.updateIdentityForFirstSixDigits(panField.textField.text!.firstSix())
        
        let validity = CardNumbersField.valid(inContext: .initial,
                                              panDelegate: panDelegate,
                                              expiryDelegate: dateDelegate,
                                              cvvDelegate: cvvDelegate)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and empty fields texts.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and empty fields texts.")
        }
    }
    
    func test_01()
    {
        let panField     = type(of: self).panField()
        let endDateField = type(of: self).endDateField()
        let cvvField     = type(of: self).cvvField()
        panField.textField.text     = nil
        endDateField.textField.text = nil
        cvvField.textField.text     = nil
        
        let manager = type(of: self).manager()
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        
        let panDelegate = CardPANFieldDelegate(withTextField  : panField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        let dateDelegate = CardExpiryDateFieldDelegate(withTextField  : endDateField,
                                                       layoutDirection: .leftToRight,
                                                       manager        : manager,
                                                       focusAction    : focusAction)
        
        let cvvDelegate = CardCVVFieldDelegate(withTextField  : cvvField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        panDelegate.manager.updateIdentityForFirstSixDigits(panField.textField.text!.firstSix())
        
        let validity = CardNumbersField.valid(inContext: .initial,
                                              panDelegate: panDelegate,
                                              expiryDelegate: dateDelegate,
                                              cvvDelegate: cvvDelegate)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for initial context and nil fields texts.")
        default     : XCTAssert(false ,
                                "Should be valid for initial context and nil fields texts.")
        }
    }
    
    // MARK: - Validation Final -
    
    func test_final_00()
    {
        let panField     = type(of: self).panField()
        let endDateField = type(of: self).endDateField()
        let cvvField     = type(of: self).cvvField()
        panField.textField.text     = ""
        endDateField.textField.text = ""
        cvvField.textField.text     = ""
        
        let manager = type(of: self).manager()
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        
        let panDelegate = CardPANFieldDelegate(withTextField  : panField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        let dateDelegate = CardExpiryDateFieldDelegate(withTextField  : endDateField,
                                                       layoutDirection: .leftToRight,
                                                       manager        : manager,
                                                       focusAction    : focusAction)
        
        let cvvDelegate = CardCVVFieldDelegate(withTextField  : cvvField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        panDelegate.manager.updateIdentityForFirstSixDigits(panField.textField.text!.firstSix())
        
        let validity = CardNumbersField.valid(inContext: .final,
                                              panDelegate: panDelegate,
                                              expiryDelegate: dateDelegate,
                                              cvvDelegate: cvvDelegate)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason.contains([.PAN, .endDate, .CVV]),
                                              "Should be invalid for final context and empty fields texts.")
        default                   : XCTAssert(false ,
                                              "Should be invalid for final context and empty fields texts.")
        }
    }
    
    func test_final_01()
    {
        let panField     = type(of: self).panField()
        let endDateField = type(of: self).endDateField()
        let cvvField     = type(of: self).cvvField()
        panField.textField.text     = nil
        endDateField.textField.text = nil
        cvvField.textField.text     = nil
        
        let manager = type(of: self).manager()
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        
        let panDelegate = CardPANFieldDelegate(withTextField  : panField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        let dateDelegate = CardExpiryDateFieldDelegate(withTextField  : endDateField,
                                                       layoutDirection: .leftToRight,
                                                       manager        : manager,
                                                       focusAction    : focusAction)
        
        let cvvDelegate = CardCVVFieldDelegate(withTextField  : cvvField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        panDelegate.manager.updateIdentityForFirstSixDigits(panField.textField.text!.firstSix())
        
        let validity = CardNumbersField.valid(inContext: .final,
                                              panDelegate: panDelegate,
                                              expiryDelegate: dateDelegate,
                                              cvvDelegate: cvvDelegate)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason.contains([.PAN, .endDate, .CVV]),
                                              "Should be final for final context and nil fields texts.")
        default                   : XCTAssert(false ,
                                              "Should be final for final context and nil fields texts.")
        }
    }
    
    func test_final_02()
    {
        let panField     = type(of: self).panField()
        let endDateField = type(of: self).endDateField()
        let cvvField     = type(of: self).cvvField()
        panField.textField.text     = "4111 1111 1111 1111"
        endDateField.textField.text = nil
        cvvField.textField.text     = nil
        
        let manager = type(of: self).manager()
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        
        let panDelegate = CardPANFieldDelegate(withTextField  : panField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        let dateDelegate = CardExpiryDateFieldDelegate(withTextField  : endDateField,
                                                       layoutDirection: .leftToRight,
                                                       manager        : manager,
                                                       focusAction    : focusAction)
        
        let cvvDelegate = CardCVVFieldDelegate(withTextField  : cvvField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        panDelegate.manager.updateIdentityForFirstSixDigits(panField.textField.text!.firstSix())
        
        let validity = CardNumbersField.valid(inContext: .final,
                                              panDelegate: panDelegate,
                                              expiryDelegate: dateDelegate,
                                              cvvDelegate: cvvDelegate)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason.contains([.endDate, .CVV]),
                                              "Should be final for final context with valid PAN and nil date field text.")
        default                   : XCTAssert(false ,
                                              "Should be final for final context with valid PAN and nil date field text.")
        }
    }
    
    func test_final_03()
    {
        let panField     = type(of: self).panField()
        let endDateField = type(of: self).endDateField()
        let cvvField     = type(of: self).cvvField()
        panField.textField.text     = "4111 1111 1111 1111"
        endDateField.textField.text = "12/33"
        cvvField.textField.text     = nil
        
        let manager = type(of: self).manager()
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        
        let panDelegate = CardPANFieldDelegate(withTextField  : panField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        let dateDelegate = CardExpiryDateFieldDelegate(withTextField  : endDateField,
                                                       layoutDirection: .leftToRight,
                                                       manager        : manager,
                                                       focusAction    : focusAction)
        
        let cvvDelegate = CardCVVFieldDelegate(withTextField  : cvvField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        panDelegate.manager.updateIdentityForFirstSixDigits(panField.textField.text!.firstSix())
        
        let validity = CardNumbersField.valid(inContext: .final,
                                              panDelegate: panDelegate,
                                              expiryDelegate: dateDelegate,
                                              cvvDelegate: cvvDelegate)
        
        switch validity
        {
        case .invalid(let reason) : XCTAssert(reason.contains([.CVV]),
                                              "Should be final for final context with valid PAN, date and nil CVV field text.")
        default                   : XCTAssert(false ,
                                              "Should be final for final context with valid PAN, date and nil CVV field text.")
        }
    }
    
    func test_final_04()
    {
        let panField     = type(of: self).panField()
        let endDateField = type(of: self).endDateField()
        let cvvField     = type(of: self).cvvField()
        panField.textField.text     = "4111 1111 1111 1111"
        endDateField.textField.text = "12/33"
        cvvField.textField.text     = "123"
        
        let manager = type(of: self).manager()
        let focusAction : CardFieldDelegate.FocusActionBlock = { (kind) in log("kind:\(kind)") }
        
        let panDelegate = CardPANFieldDelegate(withTextField  : panField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        let dateDelegate = CardExpiryDateFieldDelegate(withTextField  : endDateField,
                                                       layoutDirection: .leftToRight,
                                                       manager        : manager,
                                                       focusAction    : focusAction)
        
        let cvvDelegate = CardCVVFieldDelegate(withTextField  : cvvField,
                                               layoutDirection: .leftToRight,
                                               manager        : manager,
                                               focusAction    : focusAction)
        
        panDelegate.manager.updateIdentityForFirstSixDigits(panField.textField.text!.firstSix())
        
        let validity = CardNumbersField.valid(inContext: .final,
                                              panDelegate: panDelegate,
                                              expiryDelegate: dateDelegate,
                                              cvvDelegate: cvvDelegate)
        
        switch validity
        {
        case .valid : XCTAssert(true,
                                "Should be valid for final context and valid fields texts.")
        default     : XCTAssert(false ,
                                "Should be valid for final context and valid fields texts.")
        }
    }
    
}
