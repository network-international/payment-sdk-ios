import Foundation

struct CardDetailsValidation
{
    
    enum ValidStatus
    {
        case valid
        case invalid(reason: ValidationIssue)
    }
    
    struct ValidationIssue: OptionSet
    {
        let rawValue: Int
        
        static let PAN          = ValidationIssue(rawValue: 1 << 0)
        static let endDate      = ValidationIssue(rawValue: 1 << 1)
        static let CVV          = ValidationIssue(rawValue: 1 << 2)
        static let cardHolder   = ValidationIssue(rawValue: 1 << 3)
        
        static let all : ValidationIssue = [.PAN, .endDate, .CVV, .cardHolder]
        
    }
    
    enum ValidityContext
    {
        case initial
        case final
    }
}


protocol CardFieldValidation
{
    func valid(inContext context: CardDetailsValidation.ValidityContext) -> CardDetailsValidation.ValidStatus
    
    func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    
    func showValidity(inContext context: CardDetailsValidation.ValidityContext)
}

protocol CardFieldValidationAppearance
{
    func showAsValid(valid: Bool)
}

protocol FieldValidationMessage
{
    func fieldInvalidMessage() -> String?
}
