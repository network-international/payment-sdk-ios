import UIKit

class CardPANFieldDelegate: CardFieldDelegate
{
    typealias FormatUtility = CardPANFieldFormatUtility
    
    private var allowManualFocusChange  : Bool      = false
    private var firstSixDigits          : String?
    
    // MARK: - Condition for reformat or reset to previous -
    
    override func reformatConditionMet(forFieldText fieldText: String) -> Bool
    {
        return self.partialValidityConditionMet(for:fieldText)
    }
    
    // MARK: - Format text and preview -
    
    override func reformatDigits()
    {
        self.textField.text = FormatUtility.reformatInputField(forText          : self.textField.text,
                                                               layoutDirection  : self.layoutDirection,
                                                               maxLengthsPAN    : self.manager.maxLengthsPAN)
        self.manager.previewPAN(string: self.textField.text ?? "")
    }
    
    override func updatePreview()
    {
        self.placeholder.text = FormatUtility.preview(forText           : self.textField.text,
                                                      layoutDirection   : self.layoutDirection,
                                                      maxLengthsPAN     : self.manager.maxLengthsPAN)
    }
    
    // MARK: - FieldValidationMessage Protocol -
    
    override func fieldInvalidMessage() -> String?
    {
        return LocalizedString("error_message_PAN_invalid", comment: "")
    }
    
    // MARK: - UITextFieldDelegate -
    
    override func textField(_ textField: UITextField,
                            shouldChangeCharactersIn range: NSRange,
                            replacementString string: String) -> Bool
    {
        log("")
        guard let textFieldText = textField.text else { return false }
        self.state.previous.fieldText = textFieldText
        self.state.previous.selectedRange = textField.selectedTextRange
        
        let update = type(of: self).updateTextAttempt(text: textFieldText, shouldChangeRange: range, string: string)
        let firstSix = update.validOnly.firstSix()
        
        self.manager.updateIdentityForFirstSixDigits(firstSix)
        self.firstSixDigits = firstSix
        let lengthState = self.manager.lengthState(forPAN: update.validOnly)
        return self.shouldUpdate(lengthState: lengthState, digits: update.validOnly)
    }
   
    // MARK: - Edit field logic -
    
    private func shouldUpdate(lengthState: PANLengthState, digits: String) -> Bool
    {
        guard lengthState.contains(.isLongerThanFull) == false else
        {
            shouldUpdateForLongerPANThanFull(digits: digits)
            return false
        }
        
        if lengthState.contains([.isFull, .isLast]) && lengthState.contains(.isValid) == false
        {
            // shake
            self.field.showAsValid(valid: false)
            if let action = self.field.showErrorMessage
            {
                action(LocalizedString("error_message_PAN_invalid", comment: ""))
            }
            log("it's not valid but it's full and last")
            return true
        }
        
        if  lengthState.contains([.isFull, .isValid, .isLast]) ||
           (lengthState.contains([.isFull, .isValid]) && lengthState.contains([.isLast]) == false )
        {
            self.state.shouldMoveFocusToNext = true
            self.field.showAsValid(valid: true)
            if let action = self.field.showErrorMessage { action(nil) }
            log("shouldMoveFocusToNext = true")
        }
        
        if self.field.textField.invalidAppearance == true
        {
            log("show as valid again")
            self.field.showAsValid(valid: true)
            if let action = self.field.showErrorMessage { action(nil) }
        }
        
        return true
    }
    
    private func shouldUpdateForLongerPANThanFull(digits: String)
    {
        log("")
        //TODO: shake
        var previousState = digits
        previousState = String(previousState.dropLast())
        let lengthState = self.manager.lengthState(forPAN: previousState)
        
        if lengthState.contains([.isFull, .isValid, .isLast])
        {
            self.state.shouldMoveFocusToNext = true
            updateFocusIfNeeded()
        }
    }
    
    // MARK: - Validity Condition -
    
    override func partialValidityConditionMet(for fieldText: String) -> Bool
    {
        let digits = type(of: self).validText(from: fieldText)
        let lengthState = self.manager.lengthState(forPAN: digits)
        
        return lengthState.contains(.isLongerThanFull) == false
    }
    
    override func fullValidityConditionMet(for fieldText: String) -> Bool
    {
        let lengthState = self.manager.lengthState(forPAN: fieldText)
        return lengthState.contains([.isFull, .isValid])
    }
    
    // MARK: - CardFieldValidation Protocol -
    
    override func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    {
        return .PAN
    }
}

extension String
{
    func firstSix() -> String
    {
        return String(self.prefix(6))
    }
}
