import UIKit

class CardFormField: UIView, CardFieldValidationAppearance, ShowInlineErrorMessage, FieldValidationMessage
{
    let kind                : FormField.Kind
    var placeholder         : FormTextField!
    var textField           : FormTextField!
    var textView            : UITextView!
    var showErrorMessage    : ShowErrorMessageBlock?
    
    private var validityIndicator           : InvalidFieldIndicatorView!
    private var indicatorPositioningLabel   : UILabel?
    private let layoutDirection             : UIUserInterfaceLayoutDirection
    
    init(frame                      : CGRect,
         kind                       : FormField.Kind,
         layoutDirection            : UIUserInterfaceLayoutDirection,
         actionOnDeleteEmptyField   : VoidBlock?)
    {
        self.kind = kind
        self.layoutDirection = layoutDirection
        super.init(frame: frame)
        self.setupSubview(kind: kind,
                          layoutDirection: layoutDirection,
                          actionOnDeleteEmptyField: actionOnDeleteEmptyField)
    }
    
    override init(frame: CGRect)
    {
        self.kind = .PAN
        self.layoutDirection = .leftToRight
        super.init(frame: frame)
        self.setupSubview(kind: .PAN, layoutDirection: .leftToRight, actionOnDeleteEmptyField: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        self.kind = .PAN
        self.layoutDirection = .leftToRight
        super.init(coder: aDecoder)
    }
    
    // MARK: Subviews
    
    private func setupSubview(kind: FormField.Kind,
                              layoutDirection: UIUserInterfaceLayoutDirection,
                              actionOnDeleteEmptyField : VoidBlock?)
    {
        self.backgroundColor    = .clear
        let fields              = FormField.field(withFrame: self.bounds, kind: kind, layoutDirection: layoutDirection)
        self.placeholder        = fields.placeholderField
        self.textField          = fields.inputField
        self.textField.actionOnDeleteEmptyField = actionOnDeleteEmptyField
        self.addSubview(self.placeholder)
        self.addSubview(self.textField)
        self.addValidityIndicator()
        
        self.setupConstraints()
    }
    
    private func addValidityIndicator()
    {
        self.validityIndicator = InvalidFieldIndicatorView(frame: self.bounds)
        self.validityIndicator.isHidden = true
        self.addSubview(self.validityIndicator)
    }
    
    private func setupConstraints()
    {
        self.textField.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        self.textField.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        self.placeholder.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        self.placeholder.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    private func addIndicatorPositionLabel(for textField: FormTextField)
    {
        let textframe = textField.frame
        let label = UILabel(frame: textframe)
        label.font         = textField.font
        label.textColor    = .clear
        label.isUserInteractionEnabled = false
        self.addSubview(label)
        self.indicatorPositioningLabel = label
    }
    
    // MARK: - FieldValidationMessage Protocol -
    
    func fieldInvalidMessage() -> String?
    {
        let comment = "Error Message. Used when subclass does not implement a custom message."
        return LocalizedString("error_message_default_generic", comment: comment)
    }
    
    // MARK: - CardFieldValidationAppearance -
    
    func showAsValid(valid: Bool)
    {
        guard valid else
        {
            showInvalid()
            self.textField.invalidAppearance = true
            return
        }
        
        showValid()
        self.textField.invalidAppearance = false
    }
    
    private func showInvalid()
    {
        guard let positionLabel = self.indicatorPositioningLabel else
        {
            addIndicatorPositionLabel(for: self.textField)
            showInvalid()
            return
        }
        let text = type(of: self).stringToUseForInvalidBorder(textFieldText: self.textField.text,
                                                              placeholderText: self.placeholder.text)
        let updatedFrame = type(of: self).errorIndicatorFrame(using: positionLabel,
                                                              originalFrame: self.textField.frame,
                                                              text: text,
                                                              textAlignment:self.textField.textAlignment,
                                                              layoutDirection: self.layoutDirection)
        InvalidFieldIndicatorView.updateValidityIndicator(self.validityIndicator, for: updatedFrame)
        self.validityIndicator.isHidden = false
    }
    
    private func showValid()
    {
        self.validityIndicator.isHidden = true
    }
}

protocol CardFormFieldFocus
{
    func updateFocus()
}

// MARK: - Update Validity Indicator position and size -

extension CardFormField
{
    private class func errorIndicatorFrame(using positionLabel  : UILabel,
                                           originalFrame        : CGRect,
                                           text                 : String?,
                                           textAlignment        : NSTextAlignment,
                                           layoutDirection      : UIUserInterfaceLayoutDirection) -> CGRect
    {
        positionLabel.text = text
        positionLabel.sizeToFit()
        var updatedFrame = positionLabel.frame
        guard layoutDirection == .leftToRight || textAlignment != .right else //TODO: implement for center alignment
        {
            updatedFrame.origin.y = floor((originalFrame.size.height - updatedFrame.size.height) / 2)
            updatedFrame.origin.x = floor(originalFrame.size.width - updatedFrame.size.width)
            return updatedFrame
        }
        
        updatedFrame.origin.y = floor((originalFrame.size.height - updatedFrame.size.height) / 2)
        return updatedFrame
    }
    
    private class func stringToUseForInvalidBorder(textFieldText : String?,
                                                   placeholderText : String?) -> String?
    {
        if let text = textFieldText, let placeholder = placeholderText
        {
            return (text.count > placeholder.count) ? text : placeholder
        }
        else if let text = textFieldText
        {
            return text
        }
        return placeholderText
    }
}
