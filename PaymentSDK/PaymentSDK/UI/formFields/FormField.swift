import UIKit

struct FormField
{
    let inputField          : FormTextField
    let placeholderField    : FormTextField
    
    static func field(withFrame frame: CGRect, kind: Kind, layoutDirection: UIUserInterfaceLayoutDirection) -> FormField
    {
        let inputField       = self.inputTextField(withFrame: frame, kind: kind, layoutDirection: layoutDirection)
        let placeholderField = self.placeholderTextField(withFrame: frame, kind: kind, layoutDirection: layoutDirection)
        
        if kind == .PAN
        {
            inputField.textContentType = UITextContentType.creditCardNumber
        }
        
        return FormField(inputField       : inputField,
                         placeholderField : placeholderField)
    }
    
    enum Kind
    {
        case PAN
        case expiryDate
        case CVV
        case holderName
    }
    
    private static func inputTextField(withFrame frame: CGRect, kind: Kind, layoutDirection: UIUserInterfaceLayoutDirection) -> FormTextField
    {
        let field = self.standardTextField(frame: frame)
        field.keyboardType   = self.keyboardType(for: kind)
        field.textAlignment  = self.textAlignment(for: kind, layoutDirection: layoutDirection)
        field.textColor      = self.inputTextColor(for: kind)
        field.allowedActions = self.allowedActions(for: kind)
        return field
    }
    
    private static func placeholderTextField(withFrame frame: CGRect, kind: Kind, layoutDirection: UIUserInterfaceLayoutDirection) -> FormTextField
    {
        let field = self.standardTextField(frame: frame)
        field.isUserInteractionEnabled  = false
        field.textAlignment             = self.textAlignment(for: kind, layoutDirection: layoutDirection)
        field.textColor                 = self.placeholderTextColor(for: kind)
        return field
    }
    
    private static func standardTextField(frame: CGRect) -> FormTextField
    {
        let field = FormTextField(frame: frame)
        field.font                      = self.font()
        field.backgroundColor           = .clear
        field.autocapitalizationType    = .none
        field.autocorrectionType        = .no
        return field
    }
    
    private static func keyboardType(for kind: Kind) -> UIKeyboardType
    {
        switch kind
        {
        case .PAN           : fallthrough
        case .expiryDate    : fallthrough
        case .CVV           : return .numberPad
        case .holderName    : return .asciiCapable
        }
    }
    
    private static func textAlignment(for kind: Kind, layoutDirection: UIUserInterfaceLayoutDirection) -> NSTextAlignment
    {
        let rightToLeft = (layoutDirection == .rightToLeft)
        switch kind
        {
        case .PAN           : return rightToLeft ? .left  : .left
        case .expiryDate    : return rightToLeft ? .left  : .left
        case .CVV           : return rightToLeft ? .left  : .left
        case .holderName    : return rightToLeft ? .right : .left
        }
    }
    
    private static func allowedActions(for kind: Kind) -> AllowedFormFieldActions
    {
        switch kind
        {
        case .PAN           : return .paste
        case .holderName    : return .all
        default             : return .none
        }
    }
    
    private static func font() -> UIFont
    {
        return UIFont.systemFont(ofSize: FontSize.formField, weight: .regular)
    }
    
    private static func inputTextColor(for kind: Kind) -> UIColor
    {
        return TextColor.formFieldText
    }
    
    private static func placeholderTextColor(for kind: Kind) -> UIColor
    {
        return TextColor.formFieldPlaceholder
    }
}
