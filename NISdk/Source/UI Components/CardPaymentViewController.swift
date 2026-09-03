//
//  CardView.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import UIKit

typealias onChangeTextClosure = (UITextField) -> Void

class CardPaymentViewController: UIViewController {
    // data properties
    var makePaymentCallback: MakePaymentCallback?
    let pan = Pan()
    let cvv = Cvv()
    let cardHolderName = CardHolderName()
    let expiryDate = ExpiryDate()
    let onCancel: () -> Void?
    var isSaudiPaymentEnabled = false
    var order: OrderResponse?
    
    // ui properties
    let scrollView = UIScrollView()
    let contentView = UIView()
    var orderAmount: Amount?
    var allowedCardProviders: [CardProvider]?
    let payButton: UIButton = {
        let payButton = UIButton()
        payButton.accessibilityIdentifier = "sdk_cardpayment_button_pay"
        payButton.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor
        payButton.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonTitleColor, for: .normal)
        payButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        payButton.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonTitleColorHighlighted, for: .highlighted)
        payButton.layer.cornerRadius = 5
        payButton.setTitle("Processing Payment".localized, for: .disabled)
        return payButton
    }()
    var errorLabel: UILabel = {
        let errorLabel = UILabel()
        errorLabel.accessibilityIdentifier = "sdk_cardpayment_label_error"
        errorLabel.textColor = .red
        errorLabel.text = ""
        errorLabel.numberOfLines = 0
        errorLabel.lineBreakMode = .byWordWrapping
        return errorLabel
    }()

    // Per-field inline error labels. Each sits directly under its field so the
    // user sees exactly which input failed validation, instead of a single
    // shared message at the bottom of the form.
    private static func makeFieldErrorLabel(identifier: String) -> UILabel {
        let label = UILabel()
        label.accessibilityIdentifier = identifier
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = ""
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isHidden = true
        return label
    }

    lazy var panErrorLabel: UILabel = Self.makeFieldErrorLabel(identifier: "sdk_cardpayment_label_panError")
    lazy var expiryErrorLabel: UILabel = Self.makeFieldErrorLabel(identifier: "sdk_cardpayment_label_expiryError")
    lazy var cvvErrorLabel: UILabel = Self.makeFieldErrorLabel(identifier: "sdk_cardpayment_label_cvvError")
    lazy var nameErrorLabel: UILabel = Self.makeFieldErrorLabel(identifier: "sdk_cardpayment_label_nameError")
    
    var paymentInProgress: Bool = false {
        didSet {
            if(self.paymentInProgress) {
                self.loadingSpinner.startAnimating()
                self.payButton.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonDisabledBackgroundColor
                self.payButton.isEnabled = false
                // Lock the entire form so the user can't edit fields, tap
                // links, or otherwise interact while the payment is in flight.
                // Animations (loading spinner) keep running because UIView
                // animations don't depend on user-interaction enablement.
                self.view.endEditing(true)
                self.scrollView.isUserInteractionEnabled = false
            } else {
                self.loadingSpinner.stopAnimating()
                self.scrollView.isUserInteractionEnabled = true
                self.updatePayButtonState()
            }
        }
    }

    private var areAllFieldsFilled: Bool {
        let panFilled = !(pan.value ?? "").isEmpty
        let monthFilled = !(expiryDate.month ?? "").isEmpty
        let yearFilled = !(expiryDate.year ?? "").isEmpty
        let cvvFilled = !(cvv.value ?? "").isEmpty
        let nameFilled = !(cardHolderName.value ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        return panFilled && monthFilled && yearFilled && cvvFilled && nameFilled
    }

    private func updatePayButtonState() {
        let filled = areAllFieldsFilled
        payButton.isEnabled = filled
        payButton.backgroundColor = filled
            ? NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor
            : NISdk.sharedInstance.niSdkColors.payButtonDisabledBackgroundColor
    }
    
    let cardPreviewContainer = UIView()
    let loadingSpinner: UIActivityIndicatorView = {
        let spinner: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(style: .medium)
        } else {
            spinner = UIActivityIndicatorView(style: .white)
        }
        spinner.color = NISdk.sharedInstance.niSdkColors.payButtonActivityIndicatorColor
        spinner.isHidden = true
        spinner.hidesWhenStopped = true
        spinner.accessibilityIdentifier = "sdk_cardpayment_spinner_loading"
        return spinner
    }()
    
    fileprivate func updatePayButtonContent(_ order: OrderResponse, _ orderAmount: Amount, _ payButtonTitle: String) {
        if (order.isSaudiPaymentEnabled! && order.amount?.currencyCode == "SAR") {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 6
            stack.alignment = .center
            
            let icon = UIImageView(image: UIImage(named: "riyal", in: Bundle(for: NISdk.self), compatibleWith: nil))
            icon.contentMode = .scaleAspectFit
            icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 16).isActive = true
            
            let payLabel = UILabel()
            payLabel.text = "Pay".localized
            payLabel.textColor = .white
            payLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            
            let amountLabel = UILabel()
            amountLabel.text = orderAmount.getFormattedAmountValue()
            amountLabel.textColor = .white
            amountLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            
            stack.addArrangedSubview(payLabel)
            stack.addArrangedSubview(icon)
            stack.addArrangedSubview(amountLabel)
            
            stack.isUserInteractionEnabled = false
            for view in stack.arrangedSubviews {
                view.isUserInteractionEnabled = false
            }
            
            self.payButton.addSubview(stack)
            
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: self.payButton.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: self.payButton.centerYAnchor)
            ])
        } else {
            let font = self.payButton.titleLabel?.font ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
            let color = NISdk.sharedInstance.niSdkColors.payButtonTitleColor
            self.payButton.setAttributedTitle(
                AedSymbol.attributed(payButtonTitle, font: font, color: color),
                for: .normal)
        }
    }
    
    init(makePaymentCallback: MakePaymentCallback?, order: OrderResponse, onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
        self.order = order
        self.isSaudiPaymentEnabled = order.isSaudiPaymentEnabled ?? false
        super.init(nibName: nil, bundle: nil)
        if let makePaymentCallback = makePaymentCallback, let orderAmount = order.amount {
            self.makePaymentCallback = makePaymentCallback
            self.allowedCardProviders = order.paymentMethods?.card
            let payButtonTitle: String = if NISdk.sharedInstance.shouldShowOrderAmount {
                 String.localizedStringWithFormat("Pay Button Title".localized, orderAmount.getFormattedAmount())
            } else {
                "Pay".localized
            }
            updatePayButtonContent(order, orderAmount, payButtonTitle)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = NISdk.sharedInstance.niSdkColors.payPageBackgroundColor
        setupScrollView()
        setupCardPreviewComponent()
        setupCardInputForm()
        setupCancelButton()
        // Start disabled — enabled once all fields have content
        updatePayButtonState()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tearDownCancelButton()
    }
    
    private func setupCancelButton() {
        self.parent?.navigationController?.setNavigationBarHidden(false, animated: false)
        self.parent?.navigationItem.title = "Make Payment".localized
        let textAttributes = [NSAttributedString.Key.foregroundColor: NISdk.sharedInstance.niSdkColors.payPageTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        self.parent?.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Cancel".localized, style: .done, target: self, action: #selector(self.cancelAction))
    }
    
    private func updateCancelButtonWith(status: Bool) {
        self.parent?.navigationItem.rightBarButtonItem?.isEnabled = status
    }
    
    private func tearDownCancelButton() {
        self.parent?.navigationController?.setNavigationBarHidden(true, animated: true)
        self.parent?.navigationItem.title = nil
        self.parent?.navigationItem.rightBarButtonItem = nil
    }
    
    @objc func cancelAction() {
        self.onCancel();
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardFrame = keyboardSize.cgRectValue
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if(self.scrollView.contentInset.bottom != 0) {
            self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.keyboardDismissMode = .interactive
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                          leading: view.safeAreaLayoutGuide.leadingAnchor,
                          bottom: view.safeAreaLayoutGuide.bottomAnchor,
                          trailing: view.safeAreaLayoutGuide.trailingAnchor)
        scrollView.anchor(width: view.safeAreaLayoutGuide.widthAnchor)
        
        scrollView.addSubview(contentView)
        contentView.anchor(top: scrollView.topAnchor,
                           leading: scrollView.leadingAnchor,
                           bottom: scrollView.bottomAnchor,
                           trailing: scrollView.trailingAnchor)
        contentView.anchor(width: view.widthAnchor)
    }
    
    func setupCardPreviewComponent() {
        let cardPreviewController = CardPreviewController()
        cardPreviewController.isSaudiPaymentEnabled = self.isSaudiPaymentEnabled
        contentView.addSubview(cardPreviewContainer)
        cardPreviewContainer.anchor(top: contentView.topAnchor,
                                    leading: contentView.leadingAnchor,
                                    bottom: nil, trailing: contentView.trailingAnchor,
                                    padding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30),
                                    size: CGSize(width: 0, height: 200))
        
        add(cardPreviewController, inside: cardPreviewContainer)
        cardPreviewController.didMove(toParent: self)
    }

    func setupCardInputForm() {
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 0
        
        contentView.addSubview(vStack)
        vStack.anchor(top: cardPreviewContainer.bottomAnchor,
                      leading: contentView.leadingAnchor,
                      bottom: nil,
                      trailing: contentView.trailingAnchor,
                      padding:  UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0),
                      size: CGSize(width: 0, height: 0))
        vStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        vStack.isLayoutMarginsRelativeArrangement = true
        
        let stackBackgroundView = UIView()
        stackBackgroundView.backgroundColor = .clear
        stackBackgroundView.addBorder(.top, color: NISdk.sharedInstance.niSdkColors.payPageDividerColor , thickness: 1)
        stackBackgroundView.addBorder(.bottom, color: NISdk.sharedInstance.niSdkColors.payPageDividerColor , thickness: 1)
        stackBackgroundView.pinAsBackground(to: vStack)
        
        // Setup Pan field
        let panInputVC = PanInputVC(onChangeText: onChangePan)
        panInputVC.onEditingDidEnd = { [weak self] in self?.refreshPanFieldError() }
        panInputVC.onEditingDidBegin = { [weak self] in self?.clearFieldError(self?.panErrorLabel) }
        let panContainer = UIView()
        vStack.addArrangedSubview(panContainer)
        panContainer.anchor(heightConstant: 60)
        add(panInputVC, inside: panContainer)
        panInputVC.didMove(toParent: self)
        vStack.addArrangedSubview(wrapFieldError(panErrorLabel))

        // Setup Expiry field
        let expiryInputVC = ExpiryInputVC(onChangeMonth: onChangeMonth, onChangeYear: onChangeYear)
        expiryInputVC.onEditingDidEnd = { [weak self] in self?.refreshExpiryFieldError() }
        expiryInputVC.onEditingDidBegin = { [weak self] in self?.clearFieldError(self?.expiryErrorLabel) }
        let expiryContainer = UIView()
        vStack.addArrangedSubview(expiryContainer)
        expiryContainer.anchor(heightConstant: 60)
        add(expiryInputVC, inside: expiryContainer)
        expiryInputVC.didMove(toParent: self)
        vStack.addArrangedSubview(wrapFieldError(expiryErrorLabel))


        // Setup CVV field
        let cvvInputVC = CvvInputVC(onChangeText: onChangeCVV, cvv: self.cvv)
        cvvInputVC.onEditingDidEnd = { [weak self] in self?.refreshCvvFieldError() }
        cvvInputVC.onEditingDidBegin = { [weak self] in self?.clearFieldError(self?.cvvErrorLabel) }
        let cvvContainer = UIView()
        vStack.addArrangedSubview(cvvContainer)
        cvvContainer.anchor(heightConstant: 60)
        add(cvvInputVC, inside: cvvContainer)
        cvvInputVC.didMove(toParent: self)
        vStack.addArrangedSubview(wrapFieldError(cvvErrorLabel))

        // Setup Name field
        let nameInputVC = NameInputVC(onChangeText: onChangeName)
        nameInputVC.onEditingDidEnd = { [weak self] in self?.refreshNameFieldError() }
        nameInputVC.onEditingDidBegin = { [weak self] in self?.clearFieldError(self?.nameErrorLabel) }
        let nameContainer = UIView()
        vStack.addArrangedSubview(nameContainer)
        nameContainer.anchor(heightConstant: 60)
        add(nameInputVC, inside: nameContainer)
        nameInputVC.didMove(toParent: self)
        vStack.addArrangedSubview(wrapFieldError(nameErrorLabel))

        payButton.addTarget(self, action: #selector(payButtonAction), for: .touchUpInside)

        contentView.addSubview(payButton)
        payButton.contentHorizontalAlignment = .center
        payButton.anchor(top: vStack.bottomAnchor,
                         leading: contentView.leadingAnchor,
                         bottom: contentView.bottomAnchor,
                         trailing: contentView.trailingAnchor,
                         padding: UIEdgeInsets(top: 20, left: 30, bottom: 0, right: 30),
                         size: CGSize(width: 0, height: 50))
        
        payButton.addSubview(loadingSpinner)
        let payButtonLabel = payButton.titleLabel
        loadingSpinner.anchor(top: payButtonLabel?.topAnchor,
                              leading: payButtonLabel?.trailingAnchor,
                              bottom: nil, trailing: nil,
                              padding: UIEdgeInsets(top: 3, left: 10, bottom: 0, right: 0))
    }
    
    @objc lazy private var onChangePan: onChangeTextClosure = { [weak self] textField in
        self?.pan.value = textField.text ?? ""
        self?.updatePayButtonState()
    }

    @objc lazy private var onChangeMonth: onChangeTextClosure = { [weak self] textField in
        self?.expiryDate.month = textField.text ?? ""
        self?.updatePayButtonState()
    }

    @objc lazy private var onChangeYear: onChangeTextClosure = { [weak self] textField in
        self?.expiryDate.year = textField.text ?? ""
        self?.updatePayButtonState()
    }

    @objc lazy private var onChangeCVV: onChangeTextClosure = { [weak self] textField in
        self?.cvv.value = textField.text ?? ""
        self?.updatePayButtonState()
    }

    @objc lazy private var onChangeName: onChangeTextClosure = { [weak self] textField in
        self?.cardHolderName.value = textField.text ?? ""
        self?.updatePayButtonState()
    }
    
    /// Wraps a per-field error label in a horizontally-padded container so it
    /// aligns with the input fields above it and starts hidden (zero height
    /// when empty so it doesn't add visual gap until needed).
    private func wrapFieldError(_ label: UILabel) -> UIView {
        let container = UIView()
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
        ])
        return container
    }

    /// Routes each validation error to its dedicated field label and clears the
    /// rest. Hidden labels collapse so the form has no extra spacing when valid.
    private func applyFieldErrors(_ errors: [(String, String)]) {
        let map: [String: UILabel] = [
            "pan": panErrorLabel,
            "card-provider": panErrorLabel,
            "expiryDate": expiryErrorLabel,
            "cvv": cvvErrorLabel,
            "cardHolderName": nameErrorLabel,
        ]
        for label in Set(map.values) {
            label.text = ""
            label.isHidden = true
        }
        for (key, message) in errors {
            guard let label = map[key] else { continue }
            label.text = label.text?.isEmpty == false ? "\(label.text!)\n\(message)" : message
            label.isHidden = false
        }
    }

    /// Updates a single field's error label from the current validation state
    /// without disturbing the other fields'. Used by the on-blur callbacks so
    /// the user sees errors as soon as they leave a field, matching Android.
    private func updateSingleFieldError(label: UILabel, keys: Set<String>) {
        let (_, errors) = validateAllFields()
        let messages = errors.filter { keys.contains($0.0) }.map { $0.1 }
        if messages.isEmpty {
            label.text = ""
            label.isHidden = true
        } else {
            label.text = messages.joined(separator: "\n")
            label.isHidden = false
        }
    }

    /// Wipes a per-field error label. Called on focus-gain so the user is not
    /// staring at a stale error while editing — the error re-evaluates on
    /// blur if the value is still invalid.
    private func clearFieldError(_ label: UILabel?) {
        label?.text = ""
        label?.isHidden = true
    }

    private func refreshPanFieldError() {
        // PAN label surfaces both Luhn/length errors and the "card provider
        // not allowed" check, since both refer to the card-number input.
        updateSingleFieldError(label: panErrorLabel, keys: ["pan", "card-provider"])
    }

    private func refreshExpiryFieldError() {
        updateSingleFieldError(label: expiryErrorLabel, keys: ["expiryDate"])
    }

    private func refreshCvvFieldError() {
        updateSingleFieldError(label: cvvErrorLabel, keys: ["cvv"])
    }

    private func refreshNameFieldError() {
        updateSingleFieldError(label: nameErrorLabel, keys: ["cardHolderName"])
    }

    func validateAllFields() -> (Bool, [(String, String)]) {
        // Preserve display order so the first invalid field's message reads
        // top-to-bottom in the error label rather than depending on Dictionary order.
        var errors: [(String, String)] = []

        if !pan.validate() {
            // Distinguish wrong length (e.g. partial entry) from a fully-typed
            // number that fails the Luhn check, so the message is actionable.
            if pan.hasValidLength() {
                errors.append(("pan", "Invalid pan number".localized))
            } else {
                errors.append(("pan", "Invalid card number length".localized))
            }
        }

        if let allowedCardProviders = allowedCardProviders {
            let panProvider = pan.getCardProvider()
            let allowedCardProvidersSet: Set<CardProvider> = Set(allowedCardProviders)
            if(panProvider != .unknown && !allowedCardProvidersSet.contains(panProvider)) {
                errors.append(("card-provider", "Invalid card provider".localized))
            }
        }

        if !expiryDate.validate() {
            errors.append(("expiryDate", "Invalid expiry date".localized))
        }

        if !cvv.validate() {
            errors.append(("cvv", "Invalid CVV Field".localized))
        }

        if !cardHolderName.validate() {
            errors.append(("cardHolderName", "Invalid card holder name".localized))
        }

        return (errors.isEmpty, errors)
    }

    @objc func payButtonAction() {
        let (isAllValid, errors) = validateAllFields()
        if (isAllValid),
           let pan = pan.value,
           let expiryMonth = expiryDate.month,
           let expiryYear = expiryDate.year,
           let cvv = cvv.value,
           let cardHolderName = cardHolderName.value {
            applyFieldErrors([])
            let paymentRequest = PaymentRequest(pan: pan,
                                                expiryMonth: expiryMonth,
                                                expiryYear: expiryYear,
                                                cvv: cvv,
                                                cardHolderName: cardHolderName)
            paymentInProgress = true
            for subview in self.payButton.subviews {
                if subview is UIStackView || subview is UIActivityIndicatorView {
                    subview.removeFromSuperview()
                }
            }
            updateCancelButtonWith(status: false)
            makePaymentCallback?(paymentRequest)
            return
        }

        // Route each error to its dedicated per-field label.
        applyFieldErrors(errors)
    }
}
