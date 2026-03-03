//
//  UnifiedPaymentPageViewController.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import UIKit
import PassKit

class UnifiedPaymentPageViewController: UIViewController {

    // MARK: - Dependencies

    var makePaymentCallback: MakePaymentCallback?
    var onApplePayTapped: (() -> Void)?
    var onClickToPayTapped: (() -> Void)?
    var onAaniTapped: (() -> Void)?
    let onCancel: () -> Void
    let order: OrderResponse

    // MARK: - Card Data

    let pan = Pan()
    let cvv = Cvv()
    let cardHolderName = CardHolderName()
    let expiryDate = ExpiryDate()
    var allowedCardProviders: [CardProvider]?

    // MARK: - State

    private var selectedPaymentOption: PaymentOption?
    private var availablePaymentOptions: [PaymentOption] = []

    var paymentInProgress: Bool = false {
        didSet {
            if paymentInProgress {
                cardSection?.loadingSpinner.startAnimating()
                cardSection?.payButton.isEnabled = false
                cardSection?.payButton.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonDisabledBackgroundColor
                cardSection?.payButton.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonDisabledTitleColor, for: .normal)
                updateCancelButtonWith(status: false)
            } else {
                cardSection?.loadingSpinner.stopAnimating()
                cardSection?.payButton.isEnabled = true
                cardSection?.payButton.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor
                cardSection?.payButton.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonTitleColor, for: .normal)
                updateCancelButtonWith(status: true)
            }
        }
    }

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private var cardSection: CardPaymentSectionView?
    private var clickToPayRadioButton: RadioButtonView?
    private var clickToPayButton: UIButton?
    private var aaniRadioButton: RadioButtonView?
    private var aaniButton: UIButton?

    // MARK: - Init

    init(order: OrderResponse, onCancel: @escaping () -> Void) {
        self.order = order
        self.onCancel = onCancel
        self.allowedCardProviders = order.paymentMethods?.card
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        buildAvailablePaymentOptions()
        setupScrollView()
        buildUI()
        setupCancelButton()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tearDownCancelButton()
    }

    // MARK: - Payment Options Discovery

    private func buildAvailablePaymentOptions() {
        availablePaymentOptions = []

        // Apple Pay
        if let wallets = order.paymentMethods?.wallet {
            let hasApplePay = wallets.contains(.applePay) || wallets.contains(.directApplePay)
            if hasApplePay && NISdk.sharedInstance.deviceSupportsApplePay() {
                availablePaymentOptions.append(.applePay)
            }
        }

        // Card
        if let cards = order.paymentMethods?.card, !cards.isEmpty {
            availablePaymentOptions.append(.card)
        }

        // Click to Pay - show if the order has a click to pay link
        if order.embeddedData?.getClickToPayLink() != nil {
            availablePaymentOptions.append(.clickToPay)
        }

        // Aani - show if the order has an aani payment link
        if order.embeddedData?.getAaniPayLink() != nil {
            availablePaymentOptions.append(.aani)
        }

        // No default selection — all sections start collapsed
        selectedPaymentOption = nil
    }

    // MARK: - Layout

    private func setupScrollView() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                          leading: view.safeAreaLayoutGuide.leadingAnchor,
                          bottom: view.safeAreaLayoutGuide.bottomAnchor,
                          trailing: view.safeAreaLayoutGuide.trailingAnchor)
        scrollView.anchor(width: view.safeAreaLayoutGuide.widthAnchor)

        contentStackView.axis = .vertical
        contentStackView.spacing = 0
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        contentStackView.anchor(top: scrollView.topAnchor,
                                leading: scrollView.leadingAnchor,
                                bottom: scrollView.bottomAnchor,
                                trailing: scrollView.trailingAnchor)
        contentStackView.anchor(width: view.widthAnchor)
    }

    private func buildUI() {
        // 1. Merchant Logo Header
        let header = createMerchantLogoHeader()
        contentStackView.addArrangedSubview(header)

        // 2. Apple Pay (if available)
        if availablePaymentOptions.contains(.applePay) {
            let applePaySection = createApplePaySection()
            contentStackView.addArrangedSubview(applePaySection)
        }

        // 3. Separator
        let separator = PaymentSectionSeparatorView(text: "Or select your payment options".localized)
        contentStackView.addArrangedSubview(separator)

        // 4. Card Payment Section (if available)
        if availablePaymentOptions.contains(.card) {
            let cardSectionPadding = UIView()
            cardSectionPadding.translatesAutoresizingMaskIntoConstraints = false

            let section = CardPaymentSectionView(
                allowedCardProviders: allowedCardProviders,
                orderAmount: order.amount,
                order: order)
            section.setSelected(false)
            section.setExpanded(false, animated: false)

            section.onSelected = { [weak self] in
                self?.selectPaymentOption(.card)
            }
            section.onPayTapped = { [weak self] in
                self?.payButtonAction()
            }

            cardSectionPadding.addSubview(section)
            section.anchor(top: cardSectionPadding.topAnchor, leading: cardSectionPadding.leadingAnchor,
                           bottom: cardSectionPadding.bottomAnchor, trailing: cardSectionPadding.trailingAnchor,
                           padding: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))

            contentStackView.addArrangedSubview(cardSectionPadding)
            cardSection = section
            setupCardInputCallbacks()
        }

        // 5. Other payment options (Click to Pay, Aani, etc.)
        let hasOtherOptions = availablePaymentOptions.contains(.clickToPay) || availablePaymentOptions.contains(.aani)
        if hasOtherOptions {
            let otherHeader = createSectionHeader("Select Other Payment Options".localized)
            contentStackView.addArrangedSubview(otherHeader)

            if availablePaymentOptions.contains(.clickToPay) {
                let ctpSection = createClickToPaySection()
                contentStackView.addArrangedSubview(ctpSection)
            }

            if availablePaymentOptions.contains(.aani) {
                let aaniSection = createAaniSection()
                contentStackView.addArrangedSubview(aaniSection)
            }
        }

        // 6. Footer
        let footer = FooterView(cardProviders: order.paymentMethods?.card)
        contentStackView.addArrangedSubview(footer)
    }

    // MARK: - Merchant Logo Header

    private func createMerchantLogoHeader() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Logo — small, left-aligned
        let sdkBundle = NISdk.sharedInstance.getBundle()
        let logo = NISdk.sharedInstance.merchantLogo
            ?? UIImage(named: "networklogo", in: sdkBundle, compatibleWith: nil)

        let logoView = UIImageView(image: logo)
        logoView.contentMode = .scaleAspectFit
        logoView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(logoView)

        // Amount label — right-aligned below logo
        let amountLabel = UILabel()
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        if let amount = order.amount {
            let currency = amount.currencyCode ?? ""
            let value = amount.getFormattedAmount2Decimal().replacingOccurrences(of: currency, with: "").trimmingCharacters(in: .whitespaces)
            amountLabel.text = "\(currency) \(value)"
        }
        amountLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        amountLabel.textColor = UIColor(hexString: "#070707")
        amountLabel.textAlignment = .right
        container.addSubview(amountLabel)

        NSLayoutConstraint.activate([
            logoView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            logoView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            logoView.heightAnchor.constraint(equalToConstant: 28),
            logoView.widthAnchor.constraint(lessThanOrEqualToConstant: 120),

            amountLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 6),
            amountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            amountLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])

        return container
    }

    // MARK: - Apple Pay Section

    private func createApplePaySection() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Custom black "Pay With [Apple logo]" button
        let applePayButton = UIButton()
        applePayButton.backgroundColor = UIColor(hexString: "#070707")
        applePayButton.layer.cornerRadius = 8
        applePayButton.translatesAutoresizingMaskIntoConstraints = false
        applePayButton.addTarget(self, action: #selector(applePayTapped), for: .touchUpInside)

        // Button content: "Pay With" text + Apple logo
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 6
        buttonStack.alignment = .center
        buttonStack.isUserInteractionEnabled = false
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let payWithLabel = UILabel()
        payWithLabel.text = "Pay With".localized
        payWithLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        payWithLabel.textColor = .white

        let appleLogoView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            appleLogoView.image = UIImage(systemName: "apple.logo", withConfiguration: config)
        }
        appleLogoView.tintColor = .white
        appleLogoView.contentMode = .scaleAspectFit
        appleLogoView.translatesAutoresizingMaskIntoConstraints = false
        appleLogoView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        appleLogoView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        buttonStack.addArrangedSubview(payWithLabel)
        buttonStack.addArrangedSubview(appleLogoView)

        applePayButton.addSubview(buttonStack)
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: applePayButton.centerXAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: applePayButton.centerYAnchor),
        ])

        // Terms text
        let termsLabel = UILabel()
        termsLabel.text = "By clicking Pay terms".localized
        termsLabel.font = UIFont.systemFont(ofSize: 11)
        termsLabel.textColor = UIColor(hexString: "#8F8F8F")
        termsLabel.textAlignment = .center
        termsLabel.numberOfLines = 0
        termsLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(applePayButton)
        container.addSubview(termsLabel)

        NSLayoutConstraint.activate([
            applePayButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            applePayButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            applePayButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            applePayButton.heightAnchor.constraint(equalToConstant: 48),

            termsLabel.topAnchor.constraint(equalTo: applePayButton.bottomAnchor, constant: 8),
            termsLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            termsLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            termsLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])

        return container
    }

    // MARK: - Section Header

    private func createSectionHeader(_ title: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 48),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
        ])

        return container
    }

    // MARK: - Click to Pay Section

    private func createClickToPaySection() -> UIView {
        let outerContainer = UIView()
        outerContainer.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Radio button
        let radioButton = RadioButtonView()
        radioButton.isOn = false
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        clickToPayRadioButton = radioButton

        let radioTap = UITapGestureRecognizer(target: self, action: #selector(clickToPayRadioTapped))
        radioButton.addGestureRecognizer(radioTap)
        radioButton.isUserInteractionEnabled = true

        // Right content stack
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Title row: Click to Pay logo + "Click to Pay" label
        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        let sdkBundle = NISdk.sharedInstance.getBundle()
        let ctpLogoView = UIImageView(image: UIImage(named: "click_to_pay_payment", in: sdkBundle, compatibleWith: nil))
        ctpLogoView.contentMode = .scaleAspectFit
        ctpLogoView.translatesAutoresizingMaskIntoConstraints = false
        ctpLogoView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        ctpLogoView.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let ctpTitleLabel = UILabel()
        ctpTitleLabel.text = "Click to Pay".localized
        ctpTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        ctpTitleLabel.textColor = UIColor(hexString: "#070707")

        titleRow.addArrangedSubview(ctpLogoView)
        titleRow.addArrangedSubview(ctpTitleLabel)
        contentStack.addArrangedSubview(titleRow)

        // "Pay with Click to Pay" bordered button with CTP logo
        let ctpButton = UIButton()
        ctpButton.backgroundColor = .white
        ctpButton.layer.borderColor = UIColor(hexString: "#8F8F8F").cgColor
        ctpButton.layer.borderWidth = 1
        ctpButton.layer.cornerRadius = 8
        ctpButton.translatesAutoresizingMaskIntoConstraints = false
        ctpButton.addTarget(self, action: #selector(clickToPayTapped), for: .touchUpInside)
        ctpButton.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let ctpBtnStack = UIStackView()
        ctpBtnStack.axis = .horizontal
        ctpBtnStack.spacing = 8
        ctpBtnStack.alignment = .center
        ctpBtnStack.isUserInteractionEnabled = false
        ctpBtnStack.translatesAutoresizingMaskIntoConstraints = false

        let ctpBtnLogo = UIImageView(image: UIImage(named: "click_to_pay_payment", in: sdkBundle, compatibleWith: nil))
        ctpBtnLogo.contentMode = .scaleAspectFit
        ctpBtnLogo.translatesAutoresizingMaskIntoConstraints = false
        ctpBtnLogo.widthAnchor.constraint(equalToConstant: 24).isActive = true
        ctpBtnLogo.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let ctpBtnLabel = UILabel()
        ctpBtnLabel.text = "Pay with Click to Pay".localized
        ctpBtnLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        ctpBtnLabel.textColor = UIColor(hexString: "#070707")

        ctpBtnStack.addArrangedSubview(ctpBtnLogo)
        ctpBtnStack.addArrangedSubview(ctpBtnLabel)

        ctpButton.addSubview(ctpBtnStack)
        NSLayoutConstraint.activate([
            ctpBtnStack.centerXAnchor.constraint(equalTo: ctpButton.centerXAnchor),
            ctpBtnStack.centerYAnchor.constraint(equalTo: ctpButton.centerYAnchor),
        ])

        // Start collapsed (nothing selected by default)
        ctpButton.isHidden = true
        ctpButton.alpha = 0
        clickToPayButton = ctpButton

        contentStack.addArrangedSubview(ctpButton)

        container.addSubview(radioButton)
        container.addSubview(contentStack)

        NSLayoutConstraint.activate([
            radioButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            radioButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            contentStack.topAnchor.constraint(equalTo: container.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        outerContainer.addSubview(container)
        container.anchor(top: outerContainer.topAnchor, leading: outerContainer.leadingAnchor,
                         bottom: outerContainer.bottomAnchor, trailing: outerContainer.trailingAnchor,
                         padding: UIEdgeInsets(top: 8, left: 28, bottom: 12, right: 16))

        return outerContainer
    }

    // MARK: - Aani Section

    private func createAaniSection() -> UIView {
        let outerContainer = UIView()
        outerContainer.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Radio button
        let radioButton = RadioButtonView()
        radioButton.isOn = false
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        aaniRadioButton = radioButton

        let radioTap = UITapGestureRecognizer(target: self, action: #selector(aaniRadioTapped))
        radioButton.addGestureRecognizer(radioTap)
        radioButton.isUserInteractionEnabled = true

        // Right content stack
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Title row: Aani logo + "Aani Pay" label
        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        let sdkBundle = NISdk.sharedInstance.getBundle()
        let aaniLogoView = UIImageView(image: UIImage(named: "aaniLogo", in: sdkBundle, compatibleWith: nil))
        aaniLogoView.contentMode = .scaleAspectFit
        aaniLogoView.translatesAutoresizingMaskIntoConstraints = false
        aaniLogoView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        aaniLogoView.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let aaniTitleLabel = UILabel()
        aaniTitleLabel.text = "Pay with Aani".localized
        aaniTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        aaniTitleLabel.textColor = UIColor(hexString: "#070707")

        titleRow.addArrangedSubview(aaniLogoView)
        titleRow.addArrangedSubview(aaniTitleLabel)
        contentStack.addArrangedSubview(titleRow)

        // "Pay with Aani" bordered button
        let payButton = UIButton()
        payButton.backgroundColor = .white
        payButton.layer.borderColor = UIColor(hexString: "#8F8F8F").cgColor
        payButton.layer.borderWidth = 1
        payButton.layer.cornerRadius = 8
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.addTarget(self, action: #selector(aaniPayTapped), for: .touchUpInside)
        payButton.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let btnStack = UIStackView()
        btnStack.axis = .horizontal
        btnStack.spacing = 8
        btnStack.alignment = .center
        btnStack.isUserInteractionEnabled = false
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        let btnLogo = UIImageView(image: UIImage(named: "aaniLogo", in: sdkBundle, compatibleWith: nil))
        btnLogo.contentMode = .scaleAspectFit
        btnLogo.translatesAutoresizingMaskIntoConstraints = false
        btnLogo.widthAnchor.constraint(equalToConstant: 24).isActive = true
        btnLogo.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let btnLabel = UILabel()
        btnLabel.text = "aani_request_to_pay".localized
        btnLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        btnLabel.textColor = UIColor(hexString: "#070707")

        btnStack.addArrangedSubview(btnLogo)
        btnStack.addArrangedSubview(btnLabel)

        payButton.addSubview(btnStack)
        NSLayoutConstraint.activate([
            btnStack.centerXAnchor.constraint(equalTo: payButton.centerXAnchor),
            btnStack.centerYAnchor.constraint(equalTo: payButton.centerYAnchor),
        ])

        // Start collapsed
        payButton.isHidden = true
        payButton.alpha = 0
        aaniButton = payButton

        contentStack.addArrangedSubview(payButton)

        container.addSubview(radioButton)
        container.addSubview(contentStack)

        NSLayoutConstraint.activate([
            radioButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            radioButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            contentStack.topAnchor.constraint(equalTo: container.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        outerContainer.addSubview(container)
        container.anchor(top: outerContainer.topAnchor, leading: outerContainer.leadingAnchor,
                         bottom: outerContainer.bottomAnchor, trailing: outerContainer.trailingAnchor,
                         padding: UIEdgeInsets(top: 8, left: 28, bottom: 12, right: 16))

        return outerContainer
    }

    // MARK: - Card Input Callbacks

    private func setupCardInputCallbacks() {
        guard let cardSection = cardSection else { return }

        cardSection.onCardNumberChanged = { [weak self] text in
            self?.pan.value = text
        }
        cardSection.onExpiryMonthChanged = { [weak self] text in
            self?.expiryDate.month = text
        }
        cardSection.onExpiryYearChanged = { [weak self] text in
            self?.expiryDate.year = text
        }
        cardSection.onCvvChanged = { [weak self] text in
            self?.cvv.value = text
        }
        cardSection.onNameChanged = { [weak self] text in
            self?.cardHolderName.value = text
        }
    }

    // MARK: - Validation & Payment

    func validateAllFields() -> (Bool, [String: String]) {
        var errors: [String: String] = [:]

        if !pan.validate() {
            errors["pan"] = "Invalid pan number".localized
        }

        if let allowedCardProviders = allowedCardProviders {
            let panProvider = pan.getCardProvider()
            let allowedSet: Set<CardProvider> = Set(allowedCardProviders)
            if panProvider != .unknown && !allowedSet.contains(panProvider) {
                errors["card-provider"] = "Invalid card provider".localized
            }
        }

        if !expiryDate.validate() {
            errors["expiryDate"] = "Invalid expiry date".localized
        }

        if !cvv.validate() {
            errors["cvv"] = "Invalid CVV Field".localized
        }

        if !cardHolderName.validate() {
            errors["cardHolderName"] = "Invalid card holder name".localized
        }

        return (errors.isEmpty, errors)
    }

    @objc private func payButtonAction() {
        let (isAllValid, errors) = validateAllFields()
        if let pan = pan.value,
           let expiryMonth = expiryDate.month,
           let expiryYear = expiryDate.year,
           let cvv = cvv.value,
           let cardHolderName = cardHolderName.value {
            if isAllValid {
                cardSection?.errorLabel.text = ""
                let paymentRequest = PaymentRequest(pan: pan,
                                                     expiryMonth: expiryMonth,
                                                     expiryYear: expiryYear,
                                                     cvv: cvv,
                                                     cardHolderName: cardHolderName)
                paymentInProgress = true
                makePaymentCallback?(paymentRequest)
                return
            } else {
                if errors.count == 1 {
                    cardSection?.errorLabel.text = errors.values.first
                    return
                }
            }
        }
        cardSection?.errorLabel.text = "All fields are mandatory".localized
    }

    // MARK: - Selection

    private func selectPaymentOption(_ option: PaymentOption) {
        // If tapping the already-selected option, deselect it (collapse all)
        if selectedPaymentOption == option {
            selectedPaymentOption = nil
            cardSection?.setSelected(false)
            cardSection?.setExpanded(false, animated: false)
            clickToPayRadioButton?.isOn = false
            aaniRadioButton?.isOn = false
            self.clickToPayButton?.isHidden = true
            self.aaniButton?.isHidden = true
            UIView.animate(withDuration: 0.25) {
                self.clickToPayButton?.alpha = 0
                self.aaniButton?.alpha = 0
                self.view.layoutIfNeeded()
            }
            return
        }

        selectedPaymentOption = option

        // Update card section
        cardSection?.setSelected(option == .card)
        cardSection?.setExpanded(option == .card, animated: false)

        // Update click to pay
        clickToPayRadioButton?.isOn = (option == .clickToPay)
        let ctpExpanded = (option == .clickToPay)

        // Update aani
        aaniRadioButton?.isOn = (option == .aani)
        let aaniExpanded = (option == .aani)

        // Set hidden states immediately so UIStackView recalculates sizes
        self.clickToPayButton?.isHidden = !ctpExpanded
        self.aaniButton?.isHidden = !aaniExpanded

        // Animate alpha and layout together
        UIView.animate(withDuration: 0.25) {
            self.clickToPayButton?.alpha = ctpExpanded ? 1 : 0
            self.aaniButton?.alpha = aaniExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Actions

    @objc private func applePayTapped() {
        print("ApplePay: applePayTapped in UnifiedPaymentPage")
        onApplePayTapped?()
    }

    @objc private func clickToPayTapped() {
        onClickToPayTapped?()
    }

    @objc private func clickToPayRadioTapped() {
        selectPaymentOption(.clickToPay)
    }

    @objc private func aaniRadioTapped() {
        selectPaymentOption(.aani)
    }

    @objc private func aaniPayTapped() {
        onAaniTapped?()
    }

    // MARK: - Navigation

    private func setupCancelButton() {
        self.parent?.navigationController?.setNavigationBarHidden(false, animated: false)
        self.parent?.navigationItem.title = nil

        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .white
            appearance.shadowColor = .clear
            let plainButtonAppearance = UIBarButtonItemAppearance(style: .plain)
            plainButtonAppearance.normal.backgroundImage = UIImage()
            plainButtonAppearance.highlighted.backgroundImage = UIImage()
            appearance.buttonAppearance = plainButtonAppearance
            appearance.doneButtonAppearance = plainButtonAppearance
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.titleTextAttributes = nil
        }

        if #available(iOS 13.0, *) {
            let xImage = UIImage(systemName: "xmark",
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))?
                .withRenderingMode(.alwaysTemplate)
            let button = UIButton(type: .custom)
            button.setImage(xImage, for: .normal)
            button.tintColor = UIColor(hexString: "#070707")
            button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            button.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
            let closeButton = UIBarButtonItem(customView: button)
            self.parent?.navigationItem.rightBarButtonItem = closeButton
        } else {
            let closeButton = UIBarButtonItem(title: "✕", style: .plain,
                                              target: self, action: #selector(cancelAction))
            closeButton.tintColor = UIColor(hexString: "#070707")
            self.parent?.navigationItem.rightBarButtonItem = closeButton
        }
    }

    private func updateCancelButtonWith(status: Bool) {
        self.parent?.navigationItem.rightBarButtonItem?.isEnabled = status
    }

    private func tearDownCancelButton() {
        self.parent?.navigationController?.setNavigationBarHidden(true, animated: true)
        self.parent?.navigationItem.title = nil
        self.parent?.navigationItem.rightBarButtonItem = nil
    }

    @objc private func cancelAction() {
        self.onCancel()
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        if scrollView.contentInset.bottom != 0 {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
}
