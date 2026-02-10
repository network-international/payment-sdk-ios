//
//  CardPaymentSectionView.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import UIKit

class CardPaymentSectionView: UIView, UITextFieldDelegate {

    // MARK: - Public text fields

    let cardNumberField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Card Number".localized
        tf.keyboardType = .numberPad
        tf.font = UIFont.systemFont(ofSize: 14, weight: .light)
        tf.textColor = UIColor(hexString: "#070707")
        tf.borderStyle = .none
        tf.autocorrectionType = .no
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let expiryField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "MM/YY"
        tf.keyboardType = .numberPad
        tf.font = UIFont.systemFont(ofSize: 14, weight: .light)
        tf.textColor = UIColor(hexString: "#070707")
        tf.borderStyle = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let cvvField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "CVV".localized
        tf.keyboardType = .numberPad
        tf.font = UIFont.systemFont(ofSize: 14, weight: .light)
        tf.textColor = UIColor(hexString: "#070707")
        tf.borderStyle = .none
        tf.isSecureTextEntry = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Cardholder Name".localized
        tf.keyboardType = .asciiCapable
        tf.font = UIFont.systemFont(ofSize: 14, weight: .light)
        tf.textColor = UIColor(hexString: "#070707")
        tf.borderStyle = .none
        tf.autocorrectionType = .no
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    // MARK: - Callbacks

    var onCardNumberChanged: ((String) -> Void)?
    var onExpiryMonthChanged: ((String) -> Void)?
    var onExpiryYearChanged: ((String) -> Void)?
    var onCvvChanged: ((String) -> Void)?
    var onNameChanged: ((String) -> Void)?
    var onSelected: (() -> Void)?
    var onPayTapped: (() -> Void)?

    // MARK: - UI Components

    let payButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = UIColor(hexString: "#FFD882")
        btn.setTitleColor(UIColor(hexString: "#5C3F00"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(UIColor(hexString: "#5C3F00").withAlphaComponent(0.6), for: .highlighted)
        btn.layer.cornerRadius = 8
        btn.setTitle("Processing Payment".localized, for: .disabled)
        return btn
    }()

    let errorLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .red
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.text = ""
        lbl.textAlignment = .center
        return lbl
    }()

    let loadingSpinner: UIActivityIndicatorView = {
        let spinner: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(style: .medium)
        } else {
            spinner = UIActivityIndicatorView(style: .white)
        }
        spinner.color = UIColor(hexString: "#5C3F00")
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private let radioButton = RadioButtonView()
    private let formContainer = UIStackView()
    private let collapsedLabel = UILabel()
    private var isExpanded = false

    // MARK: - Init

    init(allowedCardProviders: [CardProvider]?, orderAmount: Amount?, order: OrderResponse?) {
        super.init(frame: .zero)
        setupView(allowedCardProviders: allowedCardProviders, orderAmount: orderAmount, order: order)
        setupTextFieldDelegates()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func setExpanded(_ expanded: Bool, animated: Bool) {
        isExpanded = expanded
        let update = {
            self.formContainer.isHidden = !expanded
            self.formContainer.alpha = expanded ? 1 : 0
            self.collapsedLabel.isHidden = expanded
            self.collapsedLabel.alpha = expanded ? 0 : 1
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: update)
        } else {
            update()
        }
    }

    func setSelected(_ selected: Bool) {
        radioButton.isOn = selected
    }

    // MARK: - Setup

    private func setupView(allowedCardProviders: [CardProvider]?, orderAmount: Amount?, order: OrderResponse?) {
        translatesAutoresizingMaskIntoConstraints = false

        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        // Title: "Use Credit Or Debit Card"
        let titleRow = createTitleRow()
        mainStack.addArrangedSubview(titleRow)

        // Card logos row
        let logosRow = createCardLogosRow(providers: allowedCardProviders)
        mainStack.addArrangedSubview(logosRow)

        radioButton.isOn = false
        radioButton.translatesAutoresizingMaskIntoConstraints = false

        // Container: radio on left, right side toggles between collapsed label and form
        let radioRow = UIView()
        radioRow.translatesAutoresizingMaskIntoConstraints = false

        // Right side content stack (switches between collapsed and expanded)
        let rightSideStack = UIStackView()
        rightSideStack.axis = .vertical
        rightSideStack.spacing = 0
        rightSideStack.translatesAutoresizingMaskIntoConstraints = false

        // Collapsed "Pay by card" label
        collapsedLabel.text = "Pay by card"
        collapsedLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        collapsedLabel.textColor = UIColor(hexString: "#070707")
        collapsedLabel.isHidden = false

        let collapsedWrapper = UIView()
        collapsedWrapper.translatesAutoresizingMaskIntoConstraints = false
        collapsedLabel.translatesAutoresizingMaskIntoConstraints = false
        collapsedWrapper.addSubview(collapsedLabel)
        NSLayoutConstraint.activate([
            collapsedWrapper.heightAnchor.constraint(equalToConstant: 26),
            collapsedLabel.leadingAnchor.constraint(equalTo: collapsedWrapper.leadingAnchor),
            collapsedLabel.centerYAnchor.constraint(equalTo: collapsedWrapper.centerYAnchor),
        ])

        // Expandable form container
        formContainer.axis = .vertical
        formContainer.spacing = 8
        formContainer.translatesAutoresizingMaskIntoConstraints = false

        // Card number field
        let cardNumberSection = createBorderedFieldSection(
            label: "Card number".localized,
            field: cardNumberField,
            trailingIcon: UIImage(systemName: "creditcard"))
        formContainer.addArrangedSubview(cardNumberSection)

        // Expiry + CVV side by side
        let expiryCvvRow = createExpiryCvvRow()
        formContainer.addArrangedSubview(expiryCvvRow)

        // Name field
        let nameSection = createBorderedFieldSection(
            label: "Name on card".localized,
            field: nameField,
            trailingIcon: UIImage(systemName: "lock.fill"))
        formContainer.addArrangedSubview(nameSection)

        // Error label
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        formContainer.addArrangedSubview(errorLabel)

        // Pay button
        let payButtonContainer = UIView()
        payButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButtonContainer.addSubview(payButton)
        payButton.anchor(top: payButtonContainer.topAnchor, leading: payButtonContainer.leadingAnchor,
                         bottom: payButtonContainer.bottomAnchor, trailing: payButtonContainer.trailingAnchor,
                         padding: UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0),
                         size: CGSize(width: 0, height: 52))
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)

        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        payButton.addSubview(loadingSpinner)
        NSLayoutConstraint.activate([
            loadingSpinner.centerYAnchor.constraint(equalTo: payButton.centerYAnchor),
            loadingSpinner.trailingAnchor.constraint(equalTo: payButton.trailingAnchor, constant: -16),
        ])

        configurePayButton(orderAmount: orderAmount, order: order)
        formContainer.addArrangedSubview(payButtonContainer)

        // Terms text
        let termsLabel = createTermsLabel()
        formContainer.addArrangedSubview(termsLabel)

        // Start collapsed: form hidden, collapsed label visible
        formContainer.isHidden = true
        formContainer.alpha = 0

        rightSideStack.addArrangedSubview(collapsedWrapper)
        rightSideStack.addArrangedSubview(formContainer)

        radioRow.addSubview(radioButton)
        radioRow.addSubview(rightSideStack)

        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        radioButton.addGestureRecognizer(tap)
        radioButton.isUserInteractionEnabled = true

        let collapsedTap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        collapsedWrapper.addGestureRecognizer(collapsedTap)
        collapsedWrapper.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            radioButton.topAnchor.constraint(equalTo: radioRow.topAnchor, constant: 4),
            radioButton.leadingAnchor.constraint(equalTo: radioRow.leadingAnchor),

            rightSideStack.topAnchor.constraint(equalTo: radioRow.topAnchor),
            rightSideStack.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 12),
            rightSideStack.trailingAnchor.constraint(equalTo: radioRow.trailingAnchor),
            rightSideStack.bottomAnchor.constraint(equalTo: radioRow.bottomAnchor),
        ])

        let paddingWrapper = UIView()
        paddingWrapper.translatesAutoresizingMaskIntoConstraints = false
        paddingWrapper.addSubview(radioRow)
        radioRow.anchor(top: paddingWrapper.topAnchor, leading: paddingWrapper.leadingAnchor,
                        bottom: paddingWrapper.bottomAnchor, trailing: paddingWrapper.trailingAnchor,
                        padding: UIEdgeInsets(top: 0, left: 12, bottom: 12, right: 12))

        mainStack.addArrangedSubview(paddingWrapper)

        addSubview(mainStack)
        mainStack.anchor(top: topAnchor, leading: leadingAnchor,
                         bottom: bottomAnchor, trailing: trailingAnchor)
    }

    // MARK: - Title Row

    private func createTitleRow() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Use Credit Or Debit Card".localized
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
        ])

        return container
    }

    // MARK: - Card Logos Row

    private func createCardLogosRow(providers: [CardProvider]?) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let logos: [(CardProvider, String)] = [
            (.masterCard, "mastercardlogo"),
            (.visa, "visalogo"),
            (.americanExpress, "amexlogo"),
            (.dinersClubInternational, "dinerslogo"),
            (.discover, "discoverlogo"),
            (.jcb, "jcblogo"),
        ]

        let sdkBundle = Bundle(for: NISdk.self)
        for (provider, imageName) in logos {
            if let allowedProviders = providers, !allowedProviders.contains(provider) {
                continue
            }
            let imageView = UIImageView(image: UIImage(named: imageName, in: sdkBundle, compatibleWith: nil))
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
            stack.addArrangedSubview(imageView)
        }

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 40),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }

    // MARK: - Bordered Field Section

    private func createBorderedFieldSection(label: String, field: UITextField, trailingIcon: UIImage?) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 0
        container.translatesAutoresizingMaskIntoConstraints = false

        // Label
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        labelView.textColor = UIColor(hexString: "#070707")
        labelView.translatesAutoresizingMaskIntoConstraints = false

        let labelWrapper = UIView()
        labelWrapper.translatesAutoresizingMaskIntoConstraints = false
        labelWrapper.addSubview(labelView)
        NSLayoutConstraint.activate([
            labelWrapper.heightAnchor.constraint(equalToConstant: 26),
            labelView.leadingAnchor.constraint(equalTo: labelWrapper.leadingAnchor),
            labelView.centerYAnchor.constraint(equalTo: labelWrapper.centerYAnchor),
        ])
        container.addArrangedSubview(labelWrapper)

        // Bordered input box
        let inputBox = UIView()
        inputBox.translatesAutoresizingMaskIntoConstraints = false
        inputBox.layer.borderColor = UIColor(hexString: "#DADADA").cgColor
        inputBox.layer.borderWidth = 1
        inputBox.layer.cornerRadius = 8
        inputBox.backgroundColor = .white

        inputBox.addSubview(field)

        if let icon = trailingIcon {
            let iconView = UIImageView(image: icon)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.contentMode = .scaleAspectFit
            iconView.tintColor = UIColor(hexString: "#4A4A4A")
            inputBox.addSubview(iconView)

            NSLayoutConstraint.activate([
                inputBox.heightAnchor.constraint(equalToConstant: 48),
                field.leadingAnchor.constraint(equalTo: inputBox.leadingAnchor, constant: 12),
                field.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -8),
                field.centerYAnchor.constraint(equalTo: inputBox.centerYAnchor),
                iconView.trailingAnchor.constraint(equalTo: inputBox.trailingAnchor, constant: -12),
                iconView.centerYAnchor.constraint(equalTo: inputBox.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 24),
                iconView.heightAnchor.constraint(equalToConstant: 24),
            ])
        } else {
            NSLayoutConstraint.activate([
                inputBox.heightAnchor.constraint(equalToConstant: 48),
                field.leadingAnchor.constraint(equalTo: inputBox.leadingAnchor, constant: 12),
                field.trailingAnchor.constraint(equalTo: inputBox.trailingAnchor, constant: -12),
                field.centerYAnchor.constraint(equalTo: inputBox.centerYAnchor),
            ])
        }

        container.addArrangedSubview(inputBox)
        return container
    }

    // MARK: - Expiry + CVV Row

    private func createExpiryCvvRow() -> UIView {
        let outerStack = UIStackView()
        outerStack.axis = .horizontal
        outerStack.spacing = 10
        outerStack.distribution = .fillEqually
        outerStack.translatesAutoresizingMaskIntoConstraints = false

        // Expiry section
        let expirySection = UIStackView()
        expirySection.axis = .vertical
        expirySection.spacing = 0

        let expiryLabel = UILabel()
        expiryLabel.text = "Expiration date".localized

        expiryLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        expiryLabel.textColor = UIColor(hexString: "#070707")

        let expiryLabelWrapper = UIView()
        expiryLabelWrapper.translatesAutoresizingMaskIntoConstraints = false
        expiryLabel.translatesAutoresizingMaskIntoConstraints = false
        expiryLabelWrapper.addSubview(expiryLabel)
        NSLayoutConstraint.activate([
            expiryLabelWrapper.heightAnchor.constraint(equalToConstant: 26),
            expiryLabel.leadingAnchor.constraint(equalTo: expiryLabelWrapper.leadingAnchor),
            expiryLabel.centerYAnchor.constraint(equalTo: expiryLabelWrapper.centerYAnchor),
        ])
        expirySection.addArrangedSubview(expiryLabelWrapper)

        let expiryBox = UIView()
        expiryBox.translatesAutoresizingMaskIntoConstraints = false
        expiryBox.layer.borderColor = UIColor(hexString: "#DADADA").cgColor
        expiryBox.layer.borderWidth = 1
        expiryBox.layer.cornerRadius = 8
        expiryBox.backgroundColor = .white

        expiryBox.addSubview(expiryField)
        NSLayoutConstraint.activate([
            expiryBox.heightAnchor.constraint(equalToConstant: 48),
            expiryField.leadingAnchor.constraint(equalTo: expiryBox.leadingAnchor, constant: 12),
            expiryField.trailingAnchor.constraint(equalTo: expiryBox.trailingAnchor, constant: -12),
            expiryField.centerYAnchor.constraint(equalTo: expiryBox.centerYAnchor),
        ])
        expirySection.addArrangedSubview(expiryBox)

        outerStack.addArrangedSubview(expirySection)

        // CVV section
        let cvvSection = UIStackView()
        cvvSection.axis = .vertical
        cvvSection.spacing = 0

        let securityLabel = UILabel()
        securityLabel.text = "Security code".localized
        securityLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        securityLabel.textColor = UIColor(hexString: "#070707")

        let securityLabelWrapper = UIView()
        securityLabelWrapper.translatesAutoresizingMaskIntoConstraints = false
        securityLabel.translatesAutoresizingMaskIntoConstraints = false
        securityLabelWrapper.addSubview(securityLabel)
        NSLayoutConstraint.activate([
            securityLabelWrapper.heightAnchor.constraint(equalToConstant: 26),
            securityLabel.leadingAnchor.constraint(equalTo: securityLabelWrapper.leadingAnchor),
            securityLabel.centerYAnchor.constraint(equalTo: securityLabelWrapper.centerYAnchor),
        ])
        cvvSection.addArrangedSubview(securityLabelWrapper)

        let cvvBox = UIView()
        cvvBox.translatesAutoresizingMaskIntoConstraints = false
        cvvBox.layer.borderColor = UIColor(hexString: "#DADADA").cgColor
        cvvBox.layer.borderWidth = 1
        cvvBox.layer.cornerRadius = 8
        cvvBox.backgroundColor = .white

        cvvBox.addSubview(cvvField)
        NSLayoutConstraint.activate([
            cvvBox.heightAnchor.constraint(equalToConstant: 48),
            cvvField.leadingAnchor.constraint(equalTo: cvvBox.leadingAnchor, constant: 12),
            cvvField.trailingAnchor.constraint(equalTo: cvvBox.trailingAnchor, constant: -12),
            cvvField.centerYAnchor.constraint(equalTo: cvvBox.centerYAnchor),
        ])
        cvvSection.addArrangedSubview(cvvBox)

        // "What's CVV?" link
        let whatsCvvLabel = UILabel()
        whatsCvvLabel.text = "What's CVV?".localized
        whatsCvvLabel.font = UIFont.systemFont(ofSize: 13, weight: .light)
        whatsCvvLabel.textColor = UIColor(hexString: "#8F8F8F")
        whatsCvvLabel.translatesAutoresizingMaskIntoConstraints = false
        cvvSection.addArrangedSubview(whatsCvvLabel)

        outerStack.addArrangedSubview(cvvSection)

        return outerStack
    }

    // MARK: - Pay Button Configuration

    private func configurePayButton(orderAmount: Amount?, order: OrderResponse?) {
        guard let orderAmount = orderAmount else {
            payButton.setTitle("Pay".localized, for: .normal)
            return
        }

        if NISdk.sharedInstance.shouldShowOrderAmount {
            if let order = order, order.isSaudiPaymentEnabled == true, orderAmount.currencyCode == "SAR" {
                configureSaudiPayButton(orderAmount: orderAmount)
            } else {
                let title = String.localizedStringWithFormat("Pay Button Title".localized, orderAmount.getFormattedAmount())
                payButton.setTitle(title, for: .normal)
            }
        } else {
            payButton.setTitle("Pay".localized, for: .normal)
        }
    }

    private func configureSaudiPayButton(orderAmount: Amount) {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center

        let payLabel = UILabel()
        payLabel.text = "Pay".localized
        payLabel.textColor = UIColor(hexString: "#5C3F00")
        payLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        let icon = UIImageView(image: UIImage(named: "riyal", in: Bundle(for: NISdk.self), compatibleWith: nil))
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let amountLabel = UILabel()
        amountLabel.text = orderAmount.getFormattedAmountValue()
        amountLabel.textColor = UIColor(hexString: "#5C3F00")
        amountLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        stack.addArrangedSubview(payLabel)
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(amountLabel)

        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        payButton.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: payButton.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: payButton.centerYAnchor),
        ])
    }

    // MARK: - Terms Label

    private func createTermsLabel() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        let text = NSMutableAttributedString(
            string: "By clicking \"Pay\", you agree to the ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .light),
                .foregroundColor: UIColor(hexString: "#8F8F8F"),
            ])
        text.append(NSAttributedString(
            string: "terms and conditions",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .light),
                .foregroundColor: UIColor(hexString: "#8F8F8F"),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ]))
        text.append(NSAttributedString(
            string: " and authorize this transaction.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .light),
                .foregroundColor: UIColor(hexString: "#8F8F8F"),
            ]))
        label.attributedText = text
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        label.anchor(top: container.topAnchor, leading: container.leadingAnchor,
                     bottom: container.bottomAnchor, trailing: container.trailingAnchor,
                     padding: UIEdgeInsets(top: 12, left: 0, bottom: 8, right: 0))

        return container
    }

    // MARK: - Text Field Delegates

    private func setupTextFieldDelegates() {
        cardNumberField.delegate = self
        expiryField.delegate = self
        cvvField.delegate = self
        nameField.delegate = self

        cardNumberField.addTarget(self, action: #selector(cardNumberDidChange(_:)), for: .editingChanged)
        expiryField.addTarget(self, action: #selector(expiryDidChange(_:)), for: .editingChanged)
        cvvField.addTarget(self, action: #selector(cvvDidChange(_:)), for: .editingChanged)
        nameField.addTarget(self, action: #selector(nameDidChange(_:)), for: .editingChanged)
    }

    @objc private func cardNumberDidChange(_ textField: UITextField) {
        onCardNumberChanged?(textField.text ?? "")
    }

    @objc private func expiryDidChange(_ textField: UITextField) {
        let text = textField.text ?? ""
        // Parse MM/YY format
        let digits = text.replacingOccurrences(of: "/", with: "")
        if digits.count >= 2 {
            let month = String(digits.prefix(2))
            let year = String(digits.dropFirst(2))
            onExpiryMonthChanged?(month)
            onExpiryYearChanged?(year)
        } else {
            onExpiryMonthChanged?(digits)
            onExpiryYearChanged?("")
        }
    }

    @objc private func cvvDidChange(_ textField: UITextField) {
        onCvvChanged?(textField.text ?? "")
    }

    @objc private func nameDidChange(_ textField: UITextField) {
        onNameChanged?(textField.text ?? "")
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let textRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)

        if textField == cardNumberField {
            let digits = updatedText.filter { $0.isNumber }
            return digits.count <= 19
        } else if textField == expiryField {
            // Handle MM/YY format with auto-slash
            let digits = updatedText.replacingOccurrences(of: "/", with: "").filter { $0.isNumber }
            if digits.count > 4 { return false }

            // Auto-format as MM/YY
            if digits.count >= 2 {
                let month = String(digits.prefix(2))
                let year = String(digits.dropFirst(2))
                textField.text = year.isEmpty ? "\(month)/" : "\(month)/\(year)"
                expiryDidChange(textField)
                return false
            }
            return true
        } else if textField == cvvField {
            let digits = updatedText.filter { $0.isNumber }
            return digits.count <= 4
        } else if textField == nameField {
            return true
        }

        return true
    }

    // MARK: - Actions

    @objc private func headerTapped() {
        onSelected?()
    }

    @objc private func payTapped() {
        onPayTapped?()
    }
}
