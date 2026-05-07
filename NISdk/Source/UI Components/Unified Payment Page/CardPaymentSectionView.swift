//
//  CardPaymentSectionView.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import UIKit

// UIStackView queries intrinsicContentSize synchronously, so this wrapper
// uses systemLayoutSizeFitting (synchronous for UIKit views) to give the
// outer stack the correct height without any async timing issues.
private final class SelfSizingContainerView: UIView {
    override var intrinsicContentSize: CGSize {
        guard let sub = subviews.first else { return .zero }
        let w = max(bounds.width, 1)
        return sub.systemLayoutSizeFitting(
            CGSize(width: w, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        superview?.setNeedsLayout()
    }
}

class CardPaymentSectionView: UIView, UITextFieldDelegate {

    // MARK: - Public text fields

    let cardNumberField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "0000 0000 0000 0000"
        tf.keyboardType = .numberPad
        tf.font = PgType.bodyInput
        tf.textColor = PgColors.textPrimary
        tf.borderStyle = .none
        tf.autocorrectionType = .no
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.accessibilityIdentifier = "sdk_card_field_cardNumber"
        return tf
    }()

    let monthField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "MM"
        tf.keyboardType = .numberPad
        tf.font = PgType.bodyInput
        tf.textColor = PgColors.textPrimary
        tf.borderStyle = .none
        tf.textAlignment = .center
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.accessibilityIdentifier = "sdk_card_field_expiryMonth"
        return tf
    }()

    let yearField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "YY"
        tf.keyboardType = .numberPad
        tf.font = PgType.bodyInput
        tf.textColor = PgColors.textPrimary
        tf.borderStyle = .none
        tf.textAlignment = .center
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.accessibilityIdentifier = "sdk_card_field_expiryYear"
        return tf
    }()

    let cvvField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "CVV".localized
        tf.keyboardType = .numberPad
        tf.font = PgType.bodyInput
        tf.textColor = PgColors.textPrimary
        tf.borderStyle = .none
        tf.isSecureTextEntry = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.accessibilityIdentifier = "sdk_card_field_cvv"
        return tf
    }()

    let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Name on card".localized
        tf.keyboardType = .asciiCapable
        tf.font = PgType.bodyInput
        tf.textColor = PgColors.textPrimary
        tf.borderStyle = .none
        tf.autocorrectionType = .no
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.accessibilityIdentifier = "sdk_card_field_cardholderName"
        return tf
    }()

    // MARK: - Callbacks

    var onCardNumberChanged: ((String) -> Void)?
    var onExpiryMonthChanged: ((String) -> Void)?
    var onExpiryYearChanged: ((String) -> Void)?
    var onCvvChanged: ((String) -> Void)?
    var onNameChanged: ((String) -> Void)?
    var onSelected: (() -> Void)?
    var onFormValidityChanged: ((Bool) -> Void)?

    // MARK: - UI Components

    let errorLabel: UILabel = {
        let lbl = UILabel()
        lbl.accessibilityIdentifier = "sdk_card_label_error"
        lbl.textColor = .red
        lbl.font = PgType.captionDisclaimer
        lbl.text = ""
        lbl.textAlignment = .center
        return lbl
    }()

    private let radioButton: RadioButtonView = {
        let rb = RadioButtonView()
        rb.accessibilityIdentifier = "sdk_card_radio_cardPayment"
        return rb
    }()
    private let formContainer = UIStackView()
    private let collapsedLabel = UILabel()
    private var isExpanded = false
    private weak var cvvTooltipContainer: UIView?
    private weak var cardNumberIconView: UIImageView?

    // Populated by parent VC to insert saved card rows between brand icons and "Pay by card"
    let savedCardsContainer: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isHidden = true
        return sv
    }()

    // Slice UI elements (managed by parent VC for hosting controller lifecycle)
    private let sliceLoaderRow: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = PgColors.spinnerPrimary
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Checking Slice eligibility..."
        label.font = PgType.captionSlicePeriod
        label.textColor = PgColors.spinnerPrimary
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 24),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }()

    let sliceInstallmentContainer: UIView = {
        let v = SelfSizingContainerView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    let visaInstallmentContainer: UIView = {
        let v = SelfSizingContainerView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

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
        formContainer.isHidden = !expanded
        if animated {
            formContainer.alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.formContainer.alpha = expanded ? 1 : 0
            }
        } else {
            formContainer.alpha = expanded ? 1 : 0
        }
    }

    func setSelected(_ selected: Bool) {
        radioButton.isOn = selected
    }

    /// Swap the card-number trailing icon to a brand logo, or fall back to the generic credit-card glyph
    /// when no brand is detected. `logoName` is the SDK bundle asset name (e.g. "visalogo"), or nil.
    func updateCardBrand(logoName: String?) {
        guard let iconView = cardNumberIconView else { return }
        if let logoName = logoName,
           let image = UIImage(named: logoName, in: NISdk.sharedInstance.getBundle(), compatibleWith: nil) {
            iconView.image = image
            iconView.tintColor = nil
        } else {
            if #available(iOS 13.0, *) {
                iconView.image = UIImage(systemName: "creditcard")
            }
            iconView.tintColor = PgColors.textSecondary
        }
    }

    // MARK: - Setup

    private func padded(_ view: UIView) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(view)
        view.anchor(top: wrapper.topAnchor, leading: wrapper.leadingAnchor,
                    bottom: wrapper.bottomAnchor, trailing: wrapper.trailingAnchor,
                    padding: UIEdgeInsets(top: 0, left: PgSpacing.rowPaddingH, bottom: 0, right: PgSpacing.rowPaddingH))
        return wrapper
    }

    private func setupView(allowedCardProviders: [CardProvider]?, orderAmount: Amount?, order: OrderResponse?) {
        translatesAutoresizingMaskIntoConstraints = false

        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        // Title: "Use Credit Or Debit Card"
        let titleRow = createTitleRow()
        mainStack.addArrangedSubview(padded(titleRow))

        // Card logos row
        let logosRow = createCardLogosRow(providers: allowedCardProviders)
        mainStack.addArrangedSubview(padded(logosRow))

        // Saved cards slot — no horizontal padding so selection background goes edge-to-edge
        mainStack.addArrangedSubview(savedCardsContainer)

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
        collapsedLabel.text = "Pay by card".localized
        collapsedLabel.font = PgType.bodyRowTitle
        collapsedLabel.textColor = PgColors.textPrimary
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
        formContainer.spacing = PgSpacing.fieldsStackGap
        formContainer.translatesAutoresizingMaskIntoConstraints = false

        // Card number field
        let cardNumberSection = createBorderedFieldSection(
            label: "Card number".localized,
            field: cardNumberField,
            trailingIcon: {
                if #available(iOS 13.0, *) { return UIImage(systemName: "creditcard") }
                return nil
            }(),
            iconViewHandler: { [weak self] iconView in
                self?.cardNumberIconView = iconView
            })
        formContainer.addArrangedSubview(cardNumberSection)

        // Slice eligibility loader (hidden until triggered)
        formContainer.addArrangedSubview(sliceLoaderRow)

        // Expiry + CVV side by side
        let expiryCvvRow = createExpiryCvvRow()
        formContainer.addArrangedSubview(expiryCvvRow)

        // "What's CVV?" link + tooltip (full width, below the expiry/CVV row)
        let cvvTooltipSection = createCvvTooltipSection()
        formContainer.addArrangedSubview(cvvTooltipSection)

        // Name field
        let nameSection = createBorderedFieldSection(
            label: "Name on card".localized,
            field: nameField,
            trailingIcon: {
                if #available(iOS 13.0, *) { return UIImage(systemName: "person") }
                return nil
            }())
        formContainer.addArrangedSubview(nameSection)

        // Error label
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        formContainer.addArrangedSubview(errorLabel)

        // Slice installment section (hidden until eligible)
        formContainer.addArrangedSubview(sliceInstallmentContainer)
        // Visa installment lives at section level (added to mainStack below) so it can render
        // for saved-card selection too, when the manual form is collapsed.

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
                        padding: UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0))

        mainStack.addArrangedSubview(padded(paddingWrapper))

        // Section-level Visa installment slot — visible for both manual and saved-card selections.
        mainStack.addArrangedSubview(padded(visaInstallmentContainer))

        addSubview(mainStack)
        mainStack.anchor(top: topAnchor, leading: leadingAnchor,
                         bottom: bottomAnchor, trailing: trailingAnchor,
                         padding: UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0))
    }

    // MARK: - Title Row

    private func createTitleRow() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Use Credit Or Debit Card".localized
        titleLabel.font = PgType.headingSection
        titleLabel.textColor = PgColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: 0),
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
            (.mada, "madalogo"),
        ]

        let sdkBundle = NISdk.sharedInstance.getBundle()
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

    private func createBorderedFieldSection(label: String, field: UITextField, trailingIcon: UIImage?, iconViewHandler: ((UIImageView) -> Void)? = nil) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 0
        container.translatesAutoresizingMaskIntoConstraints = false

        // Label
        let labelView = UILabel()
        labelView.text = label
        labelView.font = PgType.labelField
        labelView.textColor = PgColors.textPrimary
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
        inputBox.layer.borderColor = PgColors.borderInput.cgColor
        inputBox.layer.borderWidth = 1
        inputBox.layer.cornerRadius = PgRadius.input
        inputBox.backgroundColor = PgColors.surfacePage

        inputBox.addSubview(field)

        if let icon = trailingIcon {
            let iconView = UIImageView(image: icon)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.contentMode = .scaleAspectFit
            iconView.tintColor = PgColors.textSecondary
            inputBox.addSubview(iconView)
            iconViewHandler?(iconView)

            NSLayoutConstraint.activate([
                inputBox.heightAnchor.constraint(equalToConstant: PgSize.inputMinHeight),
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
                inputBox.heightAnchor.constraint(equalToConstant: PgSize.inputMinHeight),
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

        expiryLabel.font = PgType.labelField
        expiryLabel.textColor = PgColors.textPrimary

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
        expiryBox.layer.borderColor = PgColors.borderInput.cgColor
        expiryBox.layer.borderWidth = 1
        expiryBox.layer.cornerRadius = PgRadius.input
        expiryBox.backgroundColor = PgColors.surfacePage

        let slashLabel = UILabel()
        slashLabel.text = "/"
        slashLabel.font = PgType.bodyInput
        slashLabel.textColor = PgColors.textPrimary
        slashLabel.textAlignment = .center

        let expiryStack = UIStackView(arrangedSubviews: [monthField, slashLabel, yearField])
        expiryStack.axis = .horizontal
        expiryStack.spacing = 4
        expiryStack.distribution = .fill
        expiryStack.alignment = .center
        expiryStack.translatesAutoresizingMaskIntoConstraints = false
        slashLabel.setContentHuggingPriority(.required, for: .horizontal)
        slashLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        monthField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        yearField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        expiryBox.addSubview(expiryStack)
        NSLayoutConstraint.activate([
            expiryBox.heightAnchor.constraint(equalToConstant: PgSize.inputMinHeight),
            expiryStack.leadingAnchor.constraint(equalTo: expiryBox.leadingAnchor, constant: 12),
            expiryStack.trailingAnchor.constraint(equalTo: expiryBox.trailingAnchor, constant: -12),
            expiryStack.centerYAnchor.constraint(equalTo: expiryBox.centerYAnchor),
            monthField.widthAnchor.constraint(equalTo: yearField.widthAnchor),
        ])
        expirySection.addArrangedSubview(expiryBox)

        outerStack.addArrangedSubview(expirySection)

        // CVV section
        let cvvSection = UIStackView()
        cvvSection.axis = .vertical
        cvvSection.spacing = 0

        let securityLabel = UILabel()
        securityLabel.text = "Security code".localized
        securityLabel.font = PgType.labelField
        securityLabel.textColor = PgColors.textPrimary

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
        cvvBox.layer.borderColor = PgColors.borderInput.cgColor
        cvvBox.layer.borderWidth = 1
        cvvBox.layer.cornerRadius = PgRadius.input
        cvvBox.backgroundColor = PgColors.surfacePage

        cvvBox.addSubview(cvvField)
        NSLayoutConstraint.activate([
            cvvBox.heightAnchor.constraint(equalToConstant: PgSize.inputMinHeight),
            cvvField.leadingAnchor.constraint(equalTo: cvvBox.leadingAnchor, constant: 12),
            cvvField.trailingAnchor.constraint(equalTo: cvvBox.trailingAnchor, constant: -12),
            cvvField.centerYAnchor.constraint(equalTo: cvvBox.centerYAnchor),
        ])
        cvvSection.addArrangedSubview(cvvBox)

        outerStack.addArrangedSubview(cvvSection)

        return outerStack
    }

    // MARK: - CVV Tooltip Section

    private func createCvvTooltipSection() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 4
        container.translatesAutoresizingMaskIntoConstraints = false

        // "What's CVV?" label — right-aligned
        let whatsCvvLabel = UILabel()
        whatsCvvLabel.text = "What's CVV?".localized
        whatsCvvLabel.font = PgType.captionDisclaimer
        whatsCvvLabel.textColor = PgColors.textMuted
        whatsCvvLabel.textAlignment = .right
        whatsCvvLabel.translatesAutoresizingMaskIntoConstraints = false
        whatsCvvLabel.isUserInteractionEnabled = true
        container.addArrangedSubview(whatsCvvLabel)

        // Tooltip bubble (hidden by default)
        let tooltipWrapper = UIView()
        tooltipWrapper.translatesAutoresizingMaskIntoConstraints = false
        tooltipWrapper.isHidden = true

        // Arrow pointing up
        let arrowView = UIView()
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.backgroundColor = .clear
        tooltipWrapper.addSubview(arrowView)

        let arrowLayer = CAShapeLayer()
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: 0, y: 8))
        arrowPath.addLine(to: CGPoint(x: 8, y: 0))
        arrowPath.addLine(to: CGPoint(x: 16, y: 8))
        arrowPath.close()
        arrowLayer.path = arrowPath.cgPath
        arrowLayer.fillColor = UIColor(hexString: "#333333").cgColor
        arrowView.layer.addSublayer(arrowLayer)

        NSLayoutConstraint.activate([
            arrowView.topAnchor.constraint(equalTo: tooltipWrapper.topAnchor),
            arrowView.trailingAnchor.constraint(equalTo: tooltipWrapper.trailingAnchor, constant: -24),
            arrowView.widthAnchor.constraint(equalToConstant: 16),
            arrowView.heightAnchor.constraint(equalToConstant: 8),
        ])

        // Bubble body
        let bubbleView = UIView()
        bubbleView.backgroundColor = UIColor(hexString: "#333333")
        bubbleView.layer.cornerRadius = 8
        bubbleView.layer.masksToBounds = true
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        tooltipWrapper.addSubview(bubbleView)

        let cvvTooltipLabel = UILabel()
        cvvTooltipLabel.text = "CVV Tooltip".localized
        cvvTooltipLabel.font = PgType.captionDisclaimer
        cvvTooltipLabel.textColor = .white
        cvvTooltipLabel.numberOfLines = 0
        cvvTooltipLabel.textAlignment = .center
        cvvTooltipLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(cvvTooltipLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: arrowView.bottomAnchor),
            bubbleView.leadingAnchor.constraint(equalTo: tooltipWrapper.leadingAnchor),
            bubbleView.trailingAnchor.constraint(equalTo: tooltipWrapper.trailingAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: tooltipWrapper.bottomAnchor),
            cvvTooltipLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            cvvTooltipLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),
            cvvTooltipLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 16),
            cvvTooltipLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -16),
        ])

        container.addArrangedSubview(tooltipWrapper)

        let tap = UITapGestureRecognizer(target: self, action: #selector(cvvTooltipTapped))
        whatsCvvLabel.addGestureRecognizer(tap)
        self.cvvTooltipContainer = tooltipWrapper

        return container
    }

    // MARK: - Slice UI Control

    func showSliceLoader() {
        sliceLoaderRow.isHidden = false
    }

    func hideSliceLoader() {
        sliceLoaderRow.isHidden = true
    }

    func showSliceInstallmentView(_ embeddedView: UIView) {
        sliceInstallmentContainer.subviews.forEach { $0.removeFromSuperview() }
        embeddedView.translatesAutoresizingMaskIntoConstraints = false
        sliceInstallmentContainer.addSubview(embeddedView)
        // Pin all four edges: the bottom anchor lets Auto Layout self-size the container
        // to match the SwiftUI view's computed height once SwiftUI completes layout.
        NSLayoutConstraint.activate([
            embeddedView.topAnchor.constraint(equalTo: sliceInstallmentContainer.topAnchor),
            embeddedView.leadingAnchor.constraint(equalTo: sliceInstallmentContainer.leadingAnchor),
            embeddedView.trailingAnchor.constraint(equalTo: sliceInstallmentContainer.trailingAnchor),
            embeddedView.bottomAnchor.constraint(equalTo: sliceInstallmentContainer.bottomAnchor),
        ])
        sliceInstallmentContainer.isHidden = false
    }

    func hideSliceInstallmentContainer() {
        sliceInstallmentContainer.subviews.forEach { $0.removeFromSuperview() }
        sliceInstallmentContainer.isHidden = true
    }

    func showVisaInstallmentView(_ embeddedView: UIView) {
        visaInstallmentContainer.subviews.forEach { $0.removeFromSuperview() }
        embeddedView.translatesAutoresizingMaskIntoConstraints = false
        visaInstallmentContainer.addSubview(embeddedView)
        NSLayoutConstraint.activate([
            embeddedView.topAnchor.constraint(equalTo: visaInstallmentContainer.topAnchor),
            embeddedView.leadingAnchor.constraint(equalTo: visaInstallmentContainer.leadingAnchor),
            embeddedView.trailingAnchor.constraint(equalTo: visaInstallmentContainer.trailingAnchor),
            embeddedView.bottomAnchor.constraint(equalTo: visaInstallmentContainer.bottomAnchor),
        ])
        visaInstallmentContainer.isHidden = false
    }

    func hideVisaInstallmentContainer() {
        visaInstallmentContainer.subviews.forEach { $0.removeFromSuperview() }
        visaInstallmentContainer.isHidden = true
    }

    // MARK: - Pay Button Field-State Management

    private var areAllFieldsFilled: Bool {
        let cardDigits = (cardNumberField.text ?? "").filter { $0.isNumber }
        let monthDigits = (monthField.text ?? "").filter { $0.isNumber }
        let yearDigits = (yearField.text ?? "").filter { $0.isNumber }
        let cvvDigits = (cvvField.text ?? "").filter { $0.isNumber }
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespaces)
        return !cardDigits.isEmpty && monthDigits.count == 2 && yearDigits.count == 2 && !cvvDigits.isEmpty && !name.isEmpty
    }

    private func updatePayButtonState() {
        let filled = areAllFieldsFilled
        onFormValidityChanged?(filled)
    }

    // MARK: - Text Field Delegates

    private func setupTextFieldDelegates() {
        cardNumberField.delegate = self
        monthField.delegate = self
        yearField.delegate = self
        cvvField.delegate = self
        nameField.delegate = self

        cardNumberField.addTarget(self, action: #selector(cardNumberDidChange(_:)), for: .editingChanged)
        monthField.addTarget(self, action: #selector(monthDidChange(_:)), for: .editingChanged)
        yearField.addTarget(self, action: #selector(yearDidChange(_:)), for: .editingChanged)
        cvvField.addTarget(self, action: #selector(cvvDidChange(_:)), for: .editingChanged)
        nameField.addTarget(self, action: #selector(nameDidChange(_:)), for: .editingChanged)

        let toolbar = makeDoneToolbar()
        cardNumberField.inputAccessoryView = toolbar
        monthField.inputAccessoryView = toolbar
        yearField.inputAccessoryView = toolbar
        cvvField.inputAccessoryView = toolbar
        nameField.inputAccessoryView = toolbar
    }

    private func makeDoneToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [spacer, done]
        return toolbar
    }

    @objc private func dismissKeyboard() {
        endEditing(true)
    }

    @objc private func cardNumberDidChange(_ textField: UITextField) {
        let digits = (textField.text ?? "").filter { $0.isNumber }
        onCardNumberChanged?(digits)
        updatePayButtonState()
    }

    @objc private func monthDidChange(_ textField: UITextField) {
        onExpiryMonthChanged?(textField.text ?? "")
        updatePayButtonState()
    }

    @objc private func yearDidChange(_ textField: UITextField) {
        onExpiryYearChanged?(textField.text ?? "")
        updatePayButtonState()
    }

    @objc private func cvvDidChange(_ textField: UITextField) {
        onCvvChanged?(textField.text ?? "")
        updatePayButtonState()
    }

    @objc private func nameDidChange(_ textField: UITextField) {
        onNameChanged?(textField.text ?? "")
        updatePayButtonState()
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let textRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)

        if textField == cardNumberField {
            let digits = updatedText.filter { $0.isNumber }
            if digits.count > 19 { return false }
            textField.text = formatCardNumber(digits)
            onCardNumberChanged?(digits)
            updatePayButtonState()
            return false
        } else if textField == monthField {
            let digits = updatedText.filter { $0.isNumber }
            if digits.count > 2 { return false }

            // Single digit > 1 → auto-prefix 0 (e.g., "5" → "05") and jump to year
            if digits.count == 1, let n = Int(digits), n > 1 {
                textField.text = "0\(digits)"
                monthDidChange(textField)
                yearField.becomeFirstResponder()
                return false
            }

            // Two digits: reject if month > 12 or 00
            if digits.count == 2, let n = Int(digits) {
                if n < 1 || n > 12 { return false }
                textField.text = digits
                monthDidChange(textField)
                yearField.becomeFirstResponder()
                return false
            }

            return true
        } else if textField == yearField {
            let digits = updatedText.filter { $0.isNumber }
            if digits.count > 2 { return false }

            // If empty after deletion, hop back to month for in-place edits
            if digits.isEmpty && string.isEmpty && (monthField.text?.isEmpty == false) {
                monthField.becomeFirstResponder()
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

    // MARK: - Card Number Formatting

    private func formatCardNumber(_ digits: String) -> String {
        // Groups: 4-4-4-4-3 (up to 19 digits). Inserts a space before each new group.
        var result = ""
        for (index, char) in digits.enumerated() {
            if index > 0 && index % 4 == 0 {
                result += " "
            }
            result.append(char)
        }
        return result
    }

    // MARK: - Actions

    @objc private func headerTapped() {
        onSelected?()
    }

    @objc private func cvvTooltipTapped() {
        guard let container = cvvTooltipContainer else { return }
        container.isHidden.toggle()
    }
}
