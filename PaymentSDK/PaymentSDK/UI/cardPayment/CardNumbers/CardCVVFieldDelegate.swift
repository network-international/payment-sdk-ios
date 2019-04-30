import UIKit

class CardCVVFieldDelegate: CardFieldDelegate
{
    typealias FormatUtility = CardCVVFieldFormatUtility
    
    // MARK: - Condition for reformat or reset to previous -
    
    override func reformatConditionMet(forFieldText fieldText: String) -> Bool
    {
        let digits = CardNumberFormatUtility.digitsOnly(forText: fieldText)
        return self.partialValidityConditionMet(for:digits)
    }
    
    // MARK: - Format text and preview -
    
    override func reformatDigits()
    {
        self.textField.text = FormatUtility.reformatInputField(forText: self.textField.text)
    }
    
    override func updatePreview()
    {
        self.placeholder.text = FormatUtility.preview(forText: self.textField.text, maxDigits: manager.maxLengthCVV)
    }
    
    // MARK: - FieldValidationMessage Protocol -
    
    override func fieldInvalidMessage() -> String?
    {
        return LocalizedString("error_message_card_CVV_invalid", comment: "")
    }
    
    // MARK: - UITextFieldDelegate -
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        updatePreview()
        self.manager.previewCVVPosition(showing: true)
        log("")
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason)
    {
        super.textFieldDidEndEditing(textField, reason: reason)
        self.manager.previewCVVPosition(showing: false)
    }
    
    // MARK: - Validity Condition -
    
    override func partialValidityConditionMet(for fieldText: String) -> Bool
    {
        return fieldText.count <= manager.maxLengthCVV
    }
    
    override func fullValidityConditionMet(for fieldText: String) -> Bool
    {
        return fieldText.count == manager.maxLengthCVV
    }
    
    // MARK: - CardFieldValidation Protocol -
    
    override func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    {
        return .CVV
    }
}
