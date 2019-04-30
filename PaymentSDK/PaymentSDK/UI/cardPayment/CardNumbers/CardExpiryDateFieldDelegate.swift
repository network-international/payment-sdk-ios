import UIKit

class CardExpiryDateFieldDelegate: CardFieldDelegate
{
    typealias FormatUtility = CardExpiryDateFieldFormatUtility
    
    // MARK: - Condition for reformat or reset to previous -
    
    override func reformatConditionMet(forFieldText fieldText: String) -> Bool
    {
        let digits = CardNumberFormatUtility.digitsOnly(forText: fieldText)
        return digits.count <= manager.maxEndDateLength
    }
    
    // MARK: - Format text and preview -
    
    override func reformatDigits()
    {
        self.textField.text = FormatUtility.reformatInputField(forText: self.textField.text)
    }
    
    override func updatePreview()
    {
        self.placeholder.text = FormatUtility.preview(forText: self.textField.text)
        self.manager.previewEndDate(string: self.placeholder.text ?? "")
    }
    
    // MARK: - FieldValidationMessage Protocol -
    
    override func fieldInvalidMessage() -> String?
    {
        return LocalizedString("error_message_card_end_date_invalid", comment: "")
    }
    
    // MARK: - Validity Condition -
    
    override func partialValidityConditionMet(for fieldText: String) -> Bool
    {
        return self.manager.validEndDate(fieldText)
    }
    
    override func moveToNextFieldConditionMet(forInvalid fieldText: String) -> Bool
    {
        return fieldText.count > manager.maxEndDateLength
    }
    
    override func fullValidityConditionMet(for fieldText: String) -> Bool
    {
        return fieldText.count == manager.maxEndDateLength && self.manager.validEndDate(fieldText)
    }
    
    // MARK: - CardFieldValidation Protocol -
    
    override func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    {
        return .endDate
    }
}
