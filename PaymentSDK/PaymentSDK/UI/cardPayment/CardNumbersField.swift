import UIKit

class CardNumbersField: UIView, CardFieldValidation, ShowInlineErrorMessage, FieldValidationMessage
{
    private var panField        : CardFormField!
    private var panDelegate     : CardPANFieldDelegate!
    
    private var expiryField     : CardFormField!
    private var expiryDelegate  : CardExpiryDateFieldDelegate!
    
    private var cvvField        : CardFormField!
    private var cvvDelegate     : CardCVVFieldDelegate!
    
    private var nameLabel       : CardNumbersFieldTitleLabel!
    private var layoutDirection : UIUserInterfaceLayoutDirection!
    
    private var labelsStack     : UIStackView!
    private var backgroundView  : UIView!
    
    var allFieldsShowingAsValid : Bool
    {
        get
        {
            return  panField.textField.invalidAppearance == false &&
                    expiryField.textField.invalidAppearance == false &&
                    cvvField.textField.invalidAppearance == false
        }
    }
    
    var multipleFieldsShowingInvalid : Bool
    {
        get
        {
            if allFieldsShowingAsValid
            {
                return false
            }
            
            var numberOfInvalid = 0
                
            if panField.textField.invalidAppearance { numberOfInvalid += 1 }
            if expiryField.textField.invalidAppearance { numberOfInvalid += 1 }
            guard numberOfInvalid < 2 else
            {
                return true
            }
            if cvvField.textField.invalidAppearance { numberOfInvalid += 1 }
            guard numberOfInvalid < 2 else
            {
                return true
            }
            return false
        }
    }
    
    // MARK: - ShowInlineErrorMessage Protocol -
    
    var showErrorMessage        : ShowErrorMessageBlock?
    {
        set {
            self.showErrorMessageBlock          = newValue
            self.panField.showErrorMessage      = newValue
            self.expiryField.showErrorMessage   = newValue
            self.cvvField.showErrorMessage      = newValue
        }
        
        get {
            return self.showErrorMessageBlock
        }
    }
    private var showErrorMessageBlock : ShowErrorMessageBlock?
    
    // MARK: - Init -
    
    init(frame              : CGRect,
         layoutDirection    : UIUserInterfaceLayoutDirection,
         manager            : CardDataCollectionManager)
    {
        super.init(frame: frame)
        self.setupSubview(layoutDirection: layoutDirection, manager: manager)
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setupSubview(layoutDirection: .leftToRight, manager: CardDataCollectionManager())
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    // MARK: Subviews
    
    private func setupSubview(layoutDirection: UIUserInterfaceLayoutDirection,
                              manager        : CardDataCollectionManager)
    {
        self.backgroundColor =  .clear
        self.layoutDirection = layoutDirection
        
        self.addAndPopulateStack(layoutDirection: layoutDirection, manager: manager)
        
        self.configureLabel()
        self.setupConstraints()
        self.setupDelegates(layoutDirection: layoutDirection, manager: manager)
        self.setupPlaceholders()
        self.registerFieldsWithFocusEngine(manager.focusEngine)
        self.initialFieldHiding()
    }
    
    private func addAndPopulateStack(layoutDirection: UIUserInterfaceLayoutDirection,
                                     manager        : CardDataCollectionManager)
    {
        let selfClass = type(of: self)
        
        self.panField    = selfClass.PANField(frame: self.bounds, kind: .PAN, layoutDirection:layoutDirection)
        self.nameLabel   = selfClass.fieldNameLabel(frame: self.bounds, layoutDirection:layoutDirection)
        self.expiryField = selfClass.expiryField(frame: self.bounds, kind: .expiryDate, layoutDirection:layoutDirection,
                                                 actionOnDeleteEmptyField:
        {
            [weak self] in
            self?.panField.textField.becomeFirstResponder()
        })
        self.cvvField    = selfClass.expiryField(frame: self.bounds, kind: .CVV, layoutDirection:layoutDirection,
                                                 actionOnDeleteEmptyField:
        {
            [weak self] in
            self?.expiryField.textField.becomeFirstResponder()
        })
        
        let stackView    = selfClass.stackView(frame: self.bounds)
        self.labelsStack = stackView
        
        self.addBackground(frame: self.bounds)
        self.addSubview(stackView)
        self.addSubview(self.nameLabel)
        
        StackViewSpacers.addSpacer(toStack: stackView, width:0)
        stackView.addArrangedSubview(self.panField)
        StackViewSpacers.addSpacer(toStack: stackView, width:5)
        stackView.addArrangedSubview(expiryField)
        StackViewSpacers.addFlexibleSpacer(toStack: stackView)
        stackView.addArrangedSubview(self.cvvField)
        StackViewSpacers.addSpacer(toStack: stackView, width:0)
    }
    
    private func registerFieldsWithFocusEngine(_ engine: CardDataCollectionFocusEngine)
    {
        engine.registerResponder(self.panField.textField,    forKind: .PAN)
        engine.registerResponder(self.expiryField.textField, forKind: .expiryDate)
        engine.registerResponder(self.cvvField.textField,    forKind: .CVV)
    }
    
    private func setupPlaceholders()
    {
        self.panField.placeholder.text    = PreviewDefault.PAN
        self.expiryField.placeholder.text = PreviewDefault.endDate
        self.cvvField.placeholder.text    = PreviewDefault.CVV3
    }
    
    private func setupDelegates(layoutDirection: UIUserInterfaceLayoutDirection,
                                manager : CardDataCollectionManager)
    {
        let focusAction : CardFieldDelegate.FocusActionBlock =
        {
            [weak self] (kind) in
            self?.actionForFocusOnField(kind: kind)
            self?.showTitleLabel()
        }
        
        self.panDelegate = CardPANFieldDelegate(withTextField  : self.panField,
                                                layoutDirection: layoutDirection,
                                                manager        : manager,
                                                focusAction    : focusAction)
        
        self.expiryDelegate = CardExpiryDateFieldDelegate(withTextField   : self.expiryField,
                                                          layoutDirection : layoutDirection,
                                                          manager         : manager,
                                                          focusAction     : focusAction)
        
        self.cvvDelegate = CardCVVFieldDelegate(withTextField   : self.cvvField,
                                                layoutDirection : layoutDirection,
                                                manager         :  manager,
                                                focusAction     : focusAction)
    }
    
    private func configureLabel()
    {
        self.nameLabel.showTitle(forFieldKind: .PAN)
    }
    
    private func setupConstraints()
    {
        self.panField.translatesAutoresizingMaskIntoConstraints = false
        self.expiryField.translatesAutoresizingMaskIntoConstraints = false
        
        log("pan frame:\(self.panField.frame)")
        
        self.panField.widthAnchor.constraint(equalToConstant: self.panField.frame.size.width).isActive = true
        self.expiryField.widthAnchor.constraint(equalToConstant: self.expiryField.frame.size.width).isActive = true
        self.cvvField.widthAnchor.constraint(equalToConstant: self.cvvField.frame.size.width).isActive = true
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
        self.backgroundView = view
    }
    
    // MARK: - First Responder -
    
    override func becomeFirstResponder() -> Bool
    {
        return self.panField.textField.becomeFirstResponder()
    }
    
    
    // MARK: - FieldValidationMessage Protocol -
    
    func fieldInvalidMessage() -> String?
    {
        if self.multipleFieldsShowingInvalid
        {
            return LocalizedString("error_message_card_numbers_multiple", comment: "")
        }
        
        if panField.textField.invalidAppearance     { return panDelegate.fieldInvalidMessage() }
        if expiryField.textField.invalidAppearance  { return expiryDelegate.fieldInvalidMessage() }
        if cvvField.textField.invalidAppearance     { return cvvDelegate.fieldInvalidMessage() }
        return nil
    }
    
    // MARK: - CardFieldValidation Protocol -
    
    func valid(inContext context: CardDetailsValidation.ValidityContext) -> CardDetailsValidation.ValidStatus
    {
        return type(of: self).valid(inContext       : context,
                                    panDelegate     : self.panDelegate,
                                    expiryDelegate  : self.expiryDelegate,
                                    cvvDelegate     : self.cvvDelegate)
    }
    
    func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    {
        return .all
    }
    
    func showValidity(inContext context: CardDetailsValidation.ValidityContext)
    {
        self.panDelegate.showValidity(inContext: context)
        self.expiryDelegate.showValidity(inContext: context)
        self.cvvDelegate.showValidity(inContext: context)
    }
}

// MARK: - Validation -

extension CardNumbersField
{
    class func valid(inContext context: CardDetailsValidation.ValidityContext,
                     panDelegate      : CardPANFieldDelegate,
                     expiryDelegate   : CardExpiryDateFieldDelegate,
                     cvvDelegate      : CardCVVFieldDelegate ) -> CardDetailsValidation.ValidStatus
    {
        let PANValidStatus      = panDelegate.valid(inContext:context)
        let endDateValidStatus  = expiryDelegate.valid(inContext: context)
        let CVVValidStatus      = cvvDelegate.valid(inContext: context)
        
        guard allValid(PANStaus: PANValidStatus, dateStatus: endDateValidStatus, CVVStatus: CVVValidStatus) else
        {
            return combineInvalidStatuses(PANStaus: PANValidStatus, dateStatus: endDateValidStatus, CVVStatus: CVVValidStatus)
        }
        return .valid
    }
    
    class func allValid(PANStaus    : CardDetailsValidation.ValidStatus,
                        dateStatus  : CardDetailsValidation.ValidStatus,
                        CVVStatus   : CardDetailsValidation.ValidStatus) -> Bool
    {
        guard case .valid = PANStaus    else { return false }
        guard case .valid = dateStatus  else { return false }
        guard case .valid = CVVStatus   else { return false }
        return true
    }
    
    class func combineInvalidStatuses(PANStaus    : CardDetailsValidation.ValidStatus,
                                      dateStatus  : CardDetailsValidation.ValidStatus,
                                      CVVStatus   : CardDetailsValidation.ValidStatus) -> CardDetailsValidation.ValidStatus
    {
        var reasons : CardDetailsValidation.ValidationIssue = []
        
        switch PANStaus
        {
        case .invalid(let reason): reasons.insert(reason)
        default: break
        }
        
        switch dateStatus
        {
        case .invalid(let reason): reasons.insert(reason)
        default: break
        }
        
        switch CVVStatus
        {
        case .invalid(let reason): reasons.insert(reason)
        default: break
        }
        
        return .invalid(reason: reasons)
    }
}

// MARK: - Show/Hide animations -

extension CardNumbersField
{
    private func initialFieldHiding()
    {
        self.expiryField.alpha  = 0
        self.cvvField.alpha     = 0
    }
    
    func showField(ofKind kind: FormField.Kind)
    {
        log("kind:\(kind)")
        if kind != .holderName
        {
            self.nameLabel.showTitle(forFieldKind: kind)
            
            let frame = type(of: self).nameLabelFrame(forParentFrame: self.bounds,
                                                      fieldKind: kind,
                                                      layoutDirection: self.layoutDirection)
            
            UIView.customLabelAnimation(withDuration: 0.5, animations:
            {
                self.nameLabel.frame = frame
            })
        }
    }
    
    private func actionForFocusOnField(kind: FormField.Kind)
    {
        switch kind
        {
        case .PAN           : focusOnPANAction()
        case .expiryDate    : focusOnEndDateAction()
        case .CVV           : focusOnCVVAction()
        default             : log("Should not be possible!")
        }
    }
    
    private func focusOnPANAction()
    {
        log("")
        self.showField(ofKind: .PAN)
    }
    
    private func focusOnEndDateAction()
    {
        log("")
        self.showField(ofKind: .expiryDate)
        self.expiryField.alpha = 1
    }
    
    private func focusOnCVVAction()
    {
        log("")
        self.showField(ofKind: .CVV)
        self.cvvField.alpha = 1
    }
    
    // MARK: Title
    
    func hideTitleLabel()
    {
        log("")
        self.nameLabel.isHidden = true
        self.height(constant: Size.Form.Field.fieldHeight)
        type(of: self).moveOriginToTop(for: self.labelsStack)
        type(of: self).moveOriginToTop(for: self.backgroundView)
    }
    
    func showTitleLabel()
    {
        log("")
        self.nameLabel.isHidden = false
        self.height(constant: Size.Form.Field.totalHeight)
        type(of: self).moveOrigin(for: self.labelsStack,    toPosition: Size.Form.Field.titleHeight)
        type(of: self).moveOrigin(for: self.backgroundView, toPosition: Size.Form.Field.titleHeight)
    }
    
    class func moveOriginToTop(for view: UIView)
    {
        var frame = view.frame
        frame.origin.y = 0
        view.frame = frame
    }
    
    class func moveOrigin(for view: UIView, toPosition y: CGFloat)
    {
        var frame = view.frame
        frame.origin.y = y
        view.frame = frame
    }
}

// MARK: Layout extension

extension CardNumbersField
{
    private class func stackView(frame: CGRect) -> UIStackView
    {
        let origin = CGPoint(x: 0, y: Size.Form.Field.titleHeight)
        let size   = CGSize(width: frame.size.width, height: Size.Form.Field.fieldHeight)
        let theFrame = CGRect(origin: origin, size: size)
        let stackView           = UIStackView(frame: theFrame)
        stackView.axis          = .horizontal
        stackView.distribution  = .fill
        stackView.alignment     = .fill
        stackView.spacing       = 0
        return stackView
    }
    
    private class func PANField(frame: CGRect, kind: FormField.Kind, layoutDirection: UIUserInterfaceLayoutDirection) -> CardFormField
    {
        let origin = CGPoint(x: 0, y: Size.Form.Field.titleHeight)
        let theFrame = CGRect(origin: origin, size: Size.Form.Field.PAN)
        let field = CardFormField(frame: theFrame, kind: kind, layoutDirection:layoutDirection,
                                  actionOnDeleteEmptyField: nil)
        field.setContentHuggingPriority(UILayoutPriority(1000), for: .horizontal)
        return field
    }
    
    private class func expiryField(frame: CGRect, kind: FormField.Kind, layoutDirection: UIUserInterfaceLayoutDirection,
                                   actionOnDeleteEmptyField : VoidBlock?) -> CardFormField
    {
        let origin = CGPoint(x: Size.Form.Field.PAN.width, y: Size.Form.Field.titleHeight)
        let theFrame = CGRect(origin: origin, size: Size.Form.Field.expiry)
        let field = CardFormField(frame: theFrame, kind: kind, layoutDirection:layoutDirection,
                                  actionOnDeleteEmptyField: actionOnDeleteEmptyField)
        return field
    }
    
    private class func cvvField(frame: CGRect, kind: FormField.Kind, layoutDirection: UIUserInterfaceLayoutDirection,
                                actionOnDeleteEmptyField : VoidBlock?) -> CardFormField
    {
        let origin = CGPoint(x: Size.Form.Field.CVV.width, y: Size.Form.Field.titleHeight)
        let theFrame = CGRect(origin: origin, size: Size.Form.Field.expiry)
        let field = CardFormField(frame: theFrame, kind: kind, layoutDirection:layoutDirection,
                                  actionOnDeleteEmptyField: actionOnDeleteEmptyField)
        return field
    }
    
    private class func fieldNameLabel(frame: CGRect, layoutDirection: UIUserInterfaceLayoutDirection) -> CardNumbersFieldTitleLabel
    {
        let origin = self.nameLabelOrigin(forParentFrame: frame, layoutDirection: layoutDirection)
        let theFrame = CGRect(origin: origin, size: Size.Form.Field.cardNumbersPANLabel)
        let label = CardNumbersFieldTitleLabel(frame: theFrame, layoutDirection:layoutDirection)
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
    
    private class func nameLabelFrame(forParentFrame frame : CGRect,
                                      fieldKind            : FormField.Kind,
                                      layoutDirection      : UIUserInterfaceLayoutDirection) -> CGRect
    {
        switch fieldKind
        {
        case .PAN           : return self.nameLabelPANFrame(forParentFrame: frame, layoutDirection: layoutDirection)
        case .expiryDate    : return self.nameLabelEndDateFrame(forParentFrame: frame, layoutDirection: layoutDirection)
        case .CVV           : return self.nameLabelCVVFrame(forParentFrame: frame, layoutDirection: layoutDirection)
        case .holderName    : return .zero
        }
    }
    
    private class func nameLabelPANFrame(forParentFrame frame : CGRect,
                                         layoutDirection      : UIUserInterfaceLayoutDirection) -> CGRect
    {
        let size = Size.Form.Field.cardNumbersPANLabel
        
        switch layoutDirection
        {
        case .leftToRight  : return CGRect(origin: .zero, size: size)
        case .rightToLeft  : return CGRect(x: frame.size.width - Size.Form.Field.cardNumbersPANLabel.width, y: 0,
                                           width: size.width, height:size.height)
        }
    }
    
    private class func nameLabelEndDateFrame(forParentFrame frame : CGRect,
                                             layoutDirection      : UIUserInterfaceLayoutDirection) -> CGRect
    {
        let size = Size.Form.Field.cardNumbersDateLabel
        
        switch layoutDirection
        {
        case .leftToRight  : return CGRect(origin: CGPoint(x: 200, y: 0), size: size)
        case .rightToLeft  : return CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        }
    }
    
    private class func nameLabelCVVFrame(forParentFrame frame : CGRect,
                                         layoutDirection      : UIUserInterfaceLayoutDirection) -> CGRect
    {
        let size = Size.Form.Field.cardNumbersCVVLabel
        
        switch layoutDirection
        {
        case .leftToRight  : return CGRect(origin: CGPoint(x: frame.size.width - 60, y: 0), size: size)
        case .rightToLeft  : return CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        }
    }
}
