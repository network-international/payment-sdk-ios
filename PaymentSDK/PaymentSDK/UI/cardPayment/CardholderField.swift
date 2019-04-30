import UIKit

class CardholderField: UIView, CardFieldValidation, ShowInlineErrorMessage
{
    private var field           : CardFormField!
    private var fieldDelegate   : CardholderFieldDelegate!
    private var titleLabel      : UILabel!
    let focusAction             : VoidBlock
    
    var showErrorMessage        : ShowErrorMessageBlock?
    {
        set { self.field.showErrorMessage = newValue }
        get { return self.field.showErrorMessage }
    }
    
    init(frame          : CGRect,
         layoutDirection: UIUserInterfaceLayoutDirection,
         manager        : CardDataCollectionManager,
         focusAction    : @escaping VoidBlock)
    {
        self.focusAction = focusAction
        super.init(frame: frame)
        self.setupSubview(layoutDirection: layoutDirection, manager: manager)
    }
    
    override init(frame: CGRect)
    {
        self.focusAction = {}
        super.init(frame: frame)
        self.setupSubview(layoutDirection: .leftToRight, manager: CardDataCollectionManager())
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        self.focusAction = {}
        super.init(coder: aDecoder)
    }
    
    // MARK: Subviews
    
    private func setupSubview(layoutDirection: UIUserInterfaceLayoutDirection,
                              manager : CardDataCollectionManager)
    {
        let selfClass = type(of: self)
        self.backgroundColor = .clear
        self.field      = selfClass.inputField(frame: self.bounds, kind: .holderName, layoutDirection:layoutDirection)
        self.titleLabel = selfClass.fieldNameLabel(frame: self.bounds, layoutDirection:layoutDirection)
        self.addBackground(frame: self.bounds)
        self.addSubview(self.titleLabel)
        self.addSubview(self.field)
        self.setupDelegates(layoutDirection: layoutDirection, manager: manager)
        self.setupPreviews()
        
        manager.focusEngine.registerResponder(self.field.textField, forKind: .holderName)
    }
    
    private func setupPreviews()
    {
        self.field.placeholder.text = LocalizedString("cardholder_field_preview", comment: "")
    }
    
    private func setupDelegates(layoutDirection: UIUserInterfaceLayoutDirection,
                                manager : CardDataCollectionManager)
    {
        let focusAction : CardFieldDelegate.FocusActionBlock =
        {
            [weak self] (kind) in
            self?.actionForFocusOnField()
        }
        self.fieldDelegate = CardholderFieldDelegate(withTextField  : self.field,
                                                     layoutDirection: layoutDirection,
                                                     manager        : manager,
                                                     focusAction    : focusAction)
    }
    
    private func addBackground(frame: CGRect)
    {
        let padding = Padding.form.left
        let titleHeight = Size.Form.Field.titleHeight
        let theFrame = CGRect(x: -padding, y: titleHeight,
                              width: frame.size.width + (padding * 2), height: frame.size.height - titleHeight )
        let view = UIView(frame: theFrame)
        view.backgroundColor = BackgroundColor.formField
        self.addSubview(view)
    }
    
    // MARK: - CardFieldValidation Protocol -
    
    func valid(inContext context: CardDetailsValidation.ValidityContext) -> CardDetailsValidation.ValidStatus
    {
        return self.fieldDelegate.valid(inContext:context)
    }
    
    func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    {
        return self.fieldDelegate.defaultValidationErrorReason()
    }
    
    func showValidity(inContext context: CardDetailsValidation.ValidityContext)
    {
        self.fieldDelegate.showValidity(inContext: context)
    }
}

// MARK: - Show/Hide animations -

extension CardholderField
{
    private func actionForFocusOnField()
    {
        self.focusAction()
    }
}


// MARK: Layout extension

extension CardholderField
{
    private class func inputField(frame: CGRect, kind: FormField.Kind, layoutDirection: UIUserInterfaceLayoutDirection) -> CardFormField
    {
        let origin = CGPoint(x: 0, y: Size.Form.Field.titleHeight)
        let theFrame = CGRect(origin: origin, size: CGSize(width: frame.size.width, height: Size.Form.Field.PAN.height))
        let field = CardFormField(frame: theFrame, kind: kind, layoutDirection:layoutDirection,
                                  actionOnDeleteEmptyField: nil)
        field.setContentHuggingPriority(UILayoutPriority(1000), for: .horizontal)
        return field
    }
    
    private class func fieldNameLabel(frame: CGRect, layoutDirection: UIUserInterfaceLayoutDirection) -> UILabel
    {
        let origin = self.nameLabelOrigin(forParentFrame: frame, layoutDirection: layoutDirection)
        let theFrame = CGRect(origin: origin, size: Size.Form.Field.cardNumbersPANLabel)
        let label = UILabel(frame: theFrame)
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.textColor = TextColor.formFieldTitle
        label.text = LocalizedString("card_cardholder_label_title", comment: "")
        return label
    }
    
    private class func nameLabelOrigin(forParentFrame frame: CGRect, layoutDirection: UIUserInterfaceLayoutDirection) -> CGPoint
    {
        switch layoutDirection
        {
        case .leftToRight  : return .zero
        case .rightToLeft  : return CGPoint(x: frame.size.width - Size.Form.Field.cardNumbersPANLabel.width, y: 0)
        }
    }
}
