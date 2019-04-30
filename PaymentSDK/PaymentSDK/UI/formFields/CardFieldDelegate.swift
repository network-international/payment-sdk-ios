import UIKit

class CardFieldDelegate: NSObject, UITextFieldDelegate, CardFieldValidation, FieldValidationMessage
{
    typealias FocusActionBlock = (FormField.Kind) -> ()
    
    private let kind        : FormField.Kind
    let field               : CardFormField
    let textField           : FormTextField
    let placeholder         : FormTextField
    var state               : State
    let layoutDirection     : UIUserInterfaceLayoutDirection
    let manager             : CardDataCollectionManager
    var focusAction         : FocusActionBlock?
    
    init(withTextField field: CardFormField,
         layoutDirection    : UIUserInterfaceLayoutDirection,
         manager            : CardDataCollectionManager)
    {
        self.field           = field
        self.kind            = field.kind
        self.textField       = field.textField
        self.placeholder     = field.placeholder
        self.layoutDirection = layoutDirection
        self.state           = type(of: self).initialState()
        self.manager         = manager
        
        super.init()
        
        self.setupTextFieldDelegation(forField: self.textField)
    }
    
    convenience init(withTextField field: CardFormField,
                     layoutDirection    : UIUserInterfaceLayoutDirection,
                     manager            : CardDataCollectionManager,
                     focusAction        : @escaping FocusActionBlock)
    {
        self.init(withTextField: field, layoutDirection: layoutDirection, manager: manager)
        self.focusAction = focusAction
    }
    
    private func setupTextFieldDelegation(forField field: UITextField)
    {
        field.delegate = self
        field.addTarget(self, action: #selector(reformaText(forField:)), for: .editingChanged)
    }
    
    /// Subclasses need to override this method nd return true if the preconditions have been met for the text to be
    /// updated to a new value, of false if the previous state should be kept as the new one is invalid
    ///
    /// - Parameter fieldText: The text field
    /// - Returns: true if the conditions have been met for updating the text field text and preview.
    func reformatConditionMet(forFieldText fieldText: String) -> Bool
    {
        return false
    }
    
    @objc private func reformaText(forField field: UITextField)
    {
        guard let textFieldText = field.text else { return }
        guard self.reformatConditionMet(forFieldText: textFieldText) else
        {
            log("Reformat field:\(field.text ?? "") ❌")
            field.text              = self.state.previous.fieldText
            field.selectedTextRange = self.state.previous.selectedRange
            return
        }
        log("Reformat field:\(field.text ?? "") ✅")
        reformatDigits()
        updatePreview()
        updateFocusIfNeeded()
    }
    
    // MARK: - Format -
    
    func reformatDigits()
    {
        log("")
    }
    
    // MARK: - Preview Update -
    
    func updatePreview()
    {
        log("")
    }
    
    
    // MARK: - FieldValidationMessage Protocol -
    
    func fieldInvalidMessage() -> String?
    {
        let comment = "Error Message. Used when subclass does not implement a custom message."
        return LocalizedString("error_message_default_generic", comment: comment)
    }
    
    // MARK: - UITextFieldDelegate -
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        log("")
        if let focusAction = self.focusAction
        {
            log("Do focus action.")
            focusAction(self.kind)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason)
    {
        guard case .valid = self.valid(inContext: .final) else
        {
            self.field.showAsValid(valid: false)
            if let action = self.field.showErrorMessage { action(fieldInvalidMessage()) }
            return
        }
        
        self.updateCardCacheInManager()
        
        if self.field.textField.invalidAppearance == true
        {
            self.field.showAsValid(valid: true)
            if let action = self.field.showErrorMessage { action(nil) }
        }
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        log("")
        guard let textFieldText = textField.text else { return false }
        self.state.previous.fieldText = textFieldText
        self.state.previous.selectedRange = textField.selectedTextRange
        
        let update = type(of: self).updateTextAttempt(text: textFieldText, shouldChangeRange: range, string: string)
        
        
        guard self.partialValidityConditionMet(for: update.validOnly) else
        {
            if self.moveToNextFieldConditionMet(forInvalid: update.validOnly)
            {
                self.state.shouldMoveFocusToNext = true
                updateFocusIfNeeded()
            }
            return false
        }
        
        if self.field.textField.invalidAppearance == true
        {
            log("show as valid again")
            self.field.showAsValid(valid: true)
            if let action = self.field.showErrorMessage { action(nil) }
        }
        
        if self.fullValidityConditionMet(for: update.validOnly)
        {
            self.state.shouldMoveFocusToNext = true
        }
        
        return true
    }
    
    // MARK: - Validity Condition -
    
    func partialValidityConditionMet(for fieldText: String) -> Bool
    {
        return false
    }
    
    func moveToNextFieldConditionMet(forInvalid fieldText: String) -> Bool
    {
        return true
    }
    
    func fullValidityConditionMet(for fieldText: String) -> Bool
    {
        return false
    }
    
    // MARK: - Update Manager cache -
    
    private func updateCardCacheInManager()
    {
        let text = self.textField.text ?? ""
        
        switch self.kind
        {
        case .PAN           : self.manager.updatePAN(type(of: self).validText(from: text))
        case .expiryDate    : self.manager.updateExpiryDate(text)
        case .CVV           : self.manager.updateCVV(type(of: self).validText(from: text))
        case .holderName    : self.manager.updateCardholderName(text)
        }
    }
    
    // MARK: - Updated Text -
    
    class func validText(from fullText: String) -> String
    {
        return CardNumberFormatUtility.digitsOnly(forText: fullText)
    }
    
    class func updateTextAttempt(text               : String,
                                 shouldChangeRange  : NSRange,
                                 string             : String ) -> (validOnly: String, newText: String)
    {
        let newString = text.replacingCharacters(in: Range(shouldChangeRange, in: text)!, with: string)
        let digitsOnly = self.validText(from: newString)
        return (digitsOnly, newString)
    }
    
    // MARK: - Focus -
    
    func updateFocusIfNeeded()
    {
        log("")
        guard self.state.shouldMoveFocusToNext else
        {
            log("\n\n")
            return
        }
        self.state.shouldMoveFocusToNext = false
        guard let nextFocusField = self.manager.focusEngine.nextViewToFocus(afterViewOfKind: self.kind) else
        {
            self.textField.endEditing(true)
            log("\n\n")
            return
        }
        log("next:\(nextFocusField)\n\n")
        nextFocusField.becomeFirstResponder()
    }
    
    // MARK: - Validation -
    
    func validInInitialContext(text : String?) -> CardDetailsValidation.ValidStatus
    {
        guard let fullText = text, fullText.count > 0 else { return .valid }
        let digits = type(of: self).validText(from: fullText)
        guard digits.count > 0 else { return .valid }
        
        guard self.partialValidityConditionMet(for: digits) else
        {
            let reason = self.defaultValidationErrorReason()
            return .invalid(reason: reason)
        }
        return .valid
    }
    
    func validInFinalContext(text : String?) -> CardDetailsValidation.ValidStatus
    {
        guard let fullText = text, fullText.count > 0 else
        {
            let reason = self.defaultValidationErrorReason()
            return .invalid(reason: reason)
        }
        
        let digits = type(of: self).validText(from: fullText)
        guard self.fullValidityConditionMet(for: digits) else
        {
            let reason = self.defaultValidationErrorReason()
            return .invalid(reason: reason)
        }
        return .valid
    }
    
    // MARK: - CardFieldValidation Protocol -
    
    func valid(inContext context: CardDetailsValidation.ValidityContext) -> CardDetailsValidation.ValidStatus
    {
        switch context
        {
        case .initial  : return self.validInInitialContext(text: self.textField.text)
        case .final    : return self.validInFinalContext(text: self.textField.text)
        }
    }
    
    func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    {
        return .all
    }
    
    func showValidity(inContext context: CardDetailsValidation.ValidityContext)
    {
        guard case .valid = self.valid(inContext: context) else
        {
            self.field.showAsValid(valid: false)
            if let action = self.field.showErrorMessage { action(fieldInvalidMessage()) }
            return
        }
    }
}


extension CardFieldDelegate
{
    struct State
    {
        var previous                : Previous
        var shouldMoveFocusToNext   : Bool
        
        struct Previous
        {
            var selectedRange   : UITextRange?
            var fieldText       : String?
        }
    }
    
    class func initialState() -> State
    {
        return State(previous               : .init(selectedRange  : nil,
                                                    fieldText      : nil),
                     shouldMoveFocusToNext  : false)
    }
}
