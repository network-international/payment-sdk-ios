import UIKit

class CardholderFieldDelegate: CardFieldDelegate
{
    typealias FormatUtility = CardholderFieldFormatUtility
    private var validCharacters : String = ""
    
    // MARK: - Condition for reformat or reset to previous -
    
    override func reformatConditionMet(forFieldText fieldText: String) -> Bool
    {
        self.validCharacters = FormatUtility.validTextOnly(forText: fieldText)
        return partialValidityConditionMet(for:self.validCharacters)
    }
    
    // MARK: - Format text and preview -
    
    override func reformatDigits()
    {
        self.textField.text = self.validCharacters
        self.manager.previewCardholderName(string: self.validCharacters)
    }
    
    override func updatePreview()
    {
        self.placeholder.text = FormatUtility.preview(forText: self.validCharacters)
    }
    
    // MARK: - FieldValidationMessage Protocol -
    
    override func fieldInvalidMessage() -> String
    {
        return LocalizedString("error_message_cardholder_name_invalid", comment: "")
    }
    
    // MARK: - UITextFieldDelegate -
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        // check for next step allowed
        log("")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.endEditing(true)
        return true
    }
    
    // MARK: - Update text -
    
    override class func updateTextAttempt(text               : String,
                                          shouldChangeRange  : NSRange,
                                          string             : String ) -> (validOnly: String, newText: String)
    {
        let newString = text.replacingCharacters(in: Range(shouldChangeRange, in: text)!, with: string)
        let validOnly = FormatUtility.validTextOnly(forText: newString)
        return (validOnly, newString)
    }
    
    // MARK: - Validity Condition -
    
    override func partialValidityConditionMet(for fieldText: String) -> Bool
    {
        return fieldText.count <= manager.maxLengthCardHolder
    }
    
    override func fullValidityConditionMet(for fieldText: String) -> Bool
    {
        return fieldText.count == manager.maxLengthCardHolder
    }
    
    // MARK: - CardFieldValidation Protocol -
    
    override func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    {
        return .cardHolder
    }
    
    // MARK: - Validation -
    
    override func validInInitialContext(text : String?) -> CardDetailsValidation.ValidStatus
    {
        guard let fullText = text, fullText.count > 0 else { return .valid }
        let digits = FormatUtility.validTextOnly(forText: fullText)
        guard digits.count > 0 else { return .valid }
        
        guard digits.count <= self.manager.maxLengthCardHolder else { return .invalid(reason: .cardHolder) }
        return .valid
    }
    
    override func validInFinalContext(text : String?) -> CardDetailsValidation.ValidStatus
    {
        guard let fullText = text, fullText.count > 0 else { return .invalid(reason: .cardHolder) }
        let digits = FormatUtility.validTextOnly(forText: fullText)
        guard digits.count <= self.manager.maxLengthCardHolder else { return .invalid(reason: .cardHolder) }
        return .valid
    }
}
