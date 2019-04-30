import UIKit

class CardDetailsView: UIStackView, CardFieldValidation
{
    private var preview          : CardPreviewViewController!
    
    private var cardNumbersField : CardNumbersField!
    private var cardholderField  : CardholderField!
    private var payButton        : UIButton!
    private var payAction        : VoidBlock!
    
    private var cardNumbersErrorView : ErrorMessageView!
    private var cardholderErrorView  : ErrorMessageView!
    
    init(frame          : CGRect,
         layoutDirection: UIUserInterfaceLayoutDirection,
         manager        : CardDataCollectionManager,
         payAction      : @escaping VoidBlock)
    {
        self.payAction = payAction
        super.init(frame: frame)
        self.setupSubview(layoutDirection: layoutDirection, manager: manager)
    }
    
    override init(frame: CGRect)
    {
        self.payAction = {}
        super.init(frame: frame)
        self.setupSubview(layoutDirection: .leftToRight, manager: CardDataCollectionManager())
    }
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }

    // MARK: - Subviews -
    
    private func setupSubview(layoutDirection: UIUserInterfaceLayoutDirection,
                              manager : CardDataCollectionManager)
    {
        type(of: self).setupStackView(self)
        
        self.preview = self.cardPreviewView(with: manager, in: self)
        manager.preview = self.preview
        
        self.cardNumbersField = type(of: self).numbersField(frame           : self.bounds,
                                                            layoutDirection : layoutDirection,
                                                            manager         : manager)
        let width = self.cardNumbersField.frame.size.width
        let errorFrame = CGRect(origin: .zero, size: CGSize(width: width, height: 50))
        
        self.cardNumbersErrorView = ErrorMessageView(frame: errorFrame)
        self.cardNumbersField.showErrorMessage = {
            [weak self] (message) in
            self?.cardNumbersErrorAction(forMessage: message)
        }
        
        let focusAction = self.cardholderFocusAction()
        self.cardholderField = type(of: self).nameField(frame           : self.bounds,
                                                        layoutDirection : layoutDirection,
                                                        manager         : manager,
                                                        focusAction     : focusAction)
        self.cardholderErrorView = ErrorMessageView(frame: errorFrame)
        self.cardholderField.showErrorMessage = { [weak self] (message) in
            log("\(message?.description ?? "nil")")
            self?.cardholderErrorView.update(text: message)
        }
        
        self.payButton = type(of: self).payButton(frame: self.bounds)
        
        self.addArrangedSubview(self.preview.view)
        StackViewSpacers.addSpacer(toStack: self, height: K.stackViewSpacing)
        self.addArrangedSubview(self.cardNumbersField)
        self.addArrangedSubview(self.cardNumbersErrorView)
        StackViewSpacers.addSpacer(toStack: self, height: K.stackViewSpacing)
        self.addArrangedSubview(self.cardholderField)
        self.addArrangedSubview(self.cardholderErrorView)
        StackViewSpacers.addSpacer(toStack: self, height: K.stackViewSpacing * 2)
        self.addArrangedSubview(self.payButton)
        
        setupAction(forButton: self.payButton)
        initialFieldHiding()
        self.setupPlaceholders()
    }
    
    private func setupPlaceholders()
    {
        self.preview.update(for: nil, from: .PAN,        with: PreviewDefault.PAN)
        self.preview.update(for: nil, from: .expiryDate, with: PreviewDefault.endDate)
        self.preview.update(for: nil, from: .holderName, with: PreviewDefault.name)
    }
    
    private func cardholderFocusAction() -> VoidBlock
    {
        return {
            [weak self] in
            UIView.customErrorShowAnimation {
                self?.cardholderField.isHidden = false
                self?.payButton.isHidden = false
                self?.cardNumbersField.hideTitleLabel()
            }
        }
    }
    
    private func initialFieldHiding()
    {
        self.cardholderField.isHidden = true
        self.payButton.isHidden = true
    }
    
    // MARK: - First Responder -
    
    override func becomeFirstResponder() -> Bool
    {
        return self.cardNumbersField.becomeFirstResponder()
    }
    
    // MARK: - Preview -
    
    private func cardPreviewView(with manager: CardDataCollectionManager,
                                 in stackView: UIStackView) -> CardPreviewViewController
    {
        let preview = CardPreviewViewController()
        let margins = stackView.directionalLayoutMargins
        let width = stackView.frame.size.width - (margins.leading + margins.trailing)
        preview.view.width(constant: width)
        preview.view.height(constant: floor(width / K.cardWidthHeightRatio))
        return preview
    }
    
    // MARK: - Pay button action -
    
    private func setupAction(forButton button: UIButton)
    {
        button.addTarget(self, action: #selector(payButtonAction), for: .touchUpInside)
    }
    
    @objc private func payButtonAction(sender: UIButton?)
    {
        log("tapped PAY button")
        guard let action = self.payAction else { return }
        action()
    }
    
    // MARK: - Error View handling for Card Numbers -
    
    private func cardNumbersErrorAction(forMessage message: String?)
    {
        log("\(message?.description ?? "nil")")
        
        guard let aMessage = message else
        {
            guard allNumberFieldsAreValid() else
            {
                self.showMessageForSomeFieldsInvalid()
                return
            }
            self.cardNumbersErrorView.update(text: nil)
            return
        }
        
        if self.cardNumbersField.multipleFieldsShowingInvalid
        {
            self.showMessageForSomeFieldsInvalid()
            return
        }
        
        self.cardNumbersErrorView.update(text: aMessage)
    }
    
    private func showMessageForSomeFieldsInvalid()
    {
        let message = self.cardNumbersField.fieldInvalidMessage()
        self.cardNumbersErrorView.update(text: message)
    }
    
    private func allNumberFieldsAreValid() -> Bool
    {
        return self.cardNumbersField.allFieldsShowingAsValid
    }
    
    // MARK: - CardFieldValidation Protocol -
    
    func valid(inContext context: CardDetailsValidation.ValidityContext) -> CardDetailsValidation.ValidStatus
    {
        return type(of: self).valid(inContext       : context,
                                    cardNumbersField: self.cardNumbersField,
                                    cardholderField : self.cardholderField)
    }
    
    func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    {
        return .all
    }
    
    func showValidity(inContext context: CardDetailsValidation.ValidityContext)
    {
        self.cardholderField.showValidity(inContext: context)
        self.cardNumbersField.showValidity(inContext: context)
    }
}

// MARK: - Validation -

extension CardDetailsView
{
    class func valid(inContext context: CardDetailsValidation.ValidityContext,
                     cardNumbersField : CardNumbersField,
                     cardholderField  : CardholderField ) -> CardDetailsValidation.ValidStatus
    {
        let numbersValidStatus  = cardNumbersField.valid(inContext: context)
        let holderValidStatus   = cardholderField.valid(inContext:context)
        
        guard allValid(holderStatus: holderValidStatus, numberStatus: numbersValidStatus) else
        {
            return combineInvalidStatuses(holderStatus: holderValidStatus, numberStatus: numbersValidStatus)
        }
        return .valid
    }
    
    class func allValid(holderStatus: CardDetailsValidation.ValidStatus,
                        numberStatus: CardDetailsValidation.ValidStatus) -> Bool
    {
        guard case .valid = numberStatus   else { return false }
        guard case .valid = holderStatus  else { return false }
        return true
    }
    
    class func combineInvalidStatuses(holderStatus: CardDetailsValidation.ValidStatus,
                                      numberStatus: CardDetailsValidation.ValidStatus) -> CardDetailsValidation.ValidStatus
    {
        var reasons : CardDetailsValidation.ValidationIssue = []
        
        switch holderStatus
        {
        case .invalid(let reason): reasons.insert(reason)
        default: break
        }
        
        switch numberStatus
        {
        case .invalid(let reason): reasons.insert(reason)
        default: break
        }
        
        return .invalid(reason: reasons)
    }
}

extension CardDetailsView
{
    enum K
    {
        static let stackViewSpacing : CGFloat = 15
        static let buttonWidth : CGFloat = 200
        static let buttonHeight : CGFloat = 50
        static let cardWidthHeightRatio : CGFloat = 1.5849
    }
    
    private class func setupStackView(_ stackView: UIStackView)
    {
        stackView.axis          = .vertical
        stackView.distribution  = .fill
        stackView.alignment     = .center
        stackView.spacing       = 0
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
        stackView.isLayoutMarginsRelativeArrangement = true
    }
    
    private class func numbersField(frame: CGRect,
                                    layoutDirection: UIUserInterfaceLayoutDirection,
                                    manager : CardDataCollectionManager) -> CardNumbersField
    {
        let theFrame = UIFrameUtitlity.frame(forOriginal: frame, withPadding: Padding.form.left,
                                             height: Size.Form.Field.totalHeight)
        let field = CardNumbersField(frame: theFrame, layoutDirection:layoutDirection, manager : manager)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: theFrame.size.height).isActive = true
        field.widthAnchor.constraint(equalToConstant: theFrame.size.width).isActive = true
        return field
    }
    
    private class func nameField(frame: CGRect,
                                 layoutDirection: UIUserInterfaceLayoutDirection,
                                 manager : CardDataCollectionManager,
                                 focusAction : @escaping VoidBlock) -> CardholderField
    {
        let theFrame = UIFrameUtitlity.frame(forOriginal: frame, withPadding: Padding.form.left,
                                             height: Size.Form.Field.totalHeight)
        let field = CardholderField(frame           : theFrame,
                                    layoutDirection :layoutDirection,
                                    manager         : manager,
                                    focusAction     : focusAction)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: theFrame.size.height).isActive = true
        field.widthAnchor.constraint(equalToConstant: theFrame.size.width).isActive = true
        return field
    }
    
    private class func payButton(frame: CGRect) -> UIButton
    {
        let theFrame = CGRect(origin: .zero, size: CGSize(width: K.buttonWidth, height: K.buttonHeight))
        let button = UIButton(frame: theFrame)
        button.layer.cornerRadius = 10
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: theFrame.size.height).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: theFrame.size.width).isActive = true
        button.setTitle(LocalizedString("pay_button_title", comment: ""), for: .normal)
        
        return button
    }
}
