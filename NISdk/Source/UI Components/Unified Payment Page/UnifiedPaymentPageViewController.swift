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
    var onMakeSavedCardPayment: ((SavedCard, String?, VisaRequest?) -> Void)?
    /// Slice eligibility check. The first param is either a raw PAN (manual entry) or a saved-card
    /// token, distinguished by `isSavedToken`. The receiver routes to the right API field
    /// (`pan` vs `cardToken`).
    var onCheckSliceEligibility: ((_ value: String, _ expiry: String, _ isSavedToken: Bool, _ completion: @escaping ([SliceOffer]) -> Void) -> Void)?
    /// Called to fetch Visa Installment plans. The first param is either a raw PAN (manual entry)
    /// or a saved-card token, distinguished by `isSavedToken`.
    var onCheckVisEligibility: ((_ value: String, _ isSavedToken: Bool, _ completion: @escaping (VisaPlans?) -> Void) -> Void)?
    let onCancel: () -> Void
    let order: OrderResponse

    // MARK: - Card Data

    let pan = Pan()
    let cvv = Cvv()
    let cardHolderName = CardHolderName()
    let expiryDate = ExpiryDate()
    var allowedCardProviders: [CardProvider]?

    // MARK: - Saved Cards & Order Items

    var savedCards: [SavedCard] = []
    var orderItems: [OrderItem] = []

    // MARK: - State

    private var selectedPaymentOption: PaymentOption?
    private var availablePaymentOptions: [PaymentOption] = []
    private var selectedSavedCard: SavedCard?
    private var savedCardRadioButtons: [String: RadioButtonView] = [:]
    private var savedCardCvvContainers: [String: UIView] = [:]
    private var savedCardCvvFields: [String: UITextField] = [:]
    private var savedCardRowContainers: [String: UIView] = [:]

    // Order summary collapse
    private var isOrderSummaryExpanded = true
    private var orderSummaryChevronLabel: UILabel?
    private var orderSummaryDetailContainer: UIView?

    // Bottom bar Apple Pay swap
    private var bottomApplePayButton: PKPaymentButton?

    // Slice state
    private var selectedSliceOffer: SliceOffer?
    private var lastSliceCheckKey: String?
    private var sliceInstallmentView: UIView?

    // Visa Installments state — only fired when Slice is unavailable / returns empty.
    // Keyed on the same (pan,expiry) combo so we don't refire while the user is editing.
    private var visaPlansResponse: VisaPlans?
    private var selectedVisaPlan: MatchedPlan?
    private var visaTermsAccepted: Bool = false
    private var lastVisCheckKey: String?
    private var visaInstallmentView: VisaInstallmentInlineView?

    var paymentInProgress: Bool = false {
        didSet {
            if paymentInProgress {
                bottomPaySpinner?.startAnimating()
                bottomPayButton.isEnabled = false
                bottomPayButton.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonDisabledBackgroundColor
                updateCancelButtonWith(status: false)
            } else {
                bottomPaySpinner?.stopAnimating()
                updateBottomPayButton()
                updateCancelButtonWith(status: true)
            }
        }
    }

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private var cardSection: CardPaymentSectionView?
    private var applePayRadioButton: RadioButtonView?
    private var clickToPayRadioButton: RadioButtonView?
    private var aaniRadioButton: RadioButtonView?
    private let bottomBarView = UIView()
    private var bottomBarBottomConstraint: NSLayoutConstraint?
    private let bottomPayButton = UIButton()
    private var bottomPaySpinner: UIActivityIndicatorView?
    private var isCardFormValid = false

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
        setupBottomBar()
        setupScrollView()
        buildUI()
        if !savedCards.isEmpty && availablePaymentOptions.contains(.card) {
            selectPaymentOption(.card)
        }
        populateBottomBar()
        setupCancelButton()
        setupHeaderBackground()

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
            let hasApplePay = wallets.contains(.applePay)
            if hasApplePay && NISdk.sharedInstance.deviceSupportsApplePay() {
                availablePaymentOptions.append(.applePay)
            }
        }

        // Saved cards — one slot per card (represented by a single .savedCard sentinel for discovery)
        if !savedCards.isEmpty {
            availablePaymentOptions.append(.savedCard(savedCards[0]))
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

    private func setupBottomBar() {
        bottomBarView.backgroundColor = PgColors.surfacePage
        bottomBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBarView)

        let bottomConstraint = bottomBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomBarBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            bottomBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint,
        ])
    }

    private func populateBottomBar() {
        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        bottomBarView.addSubview(separator)

        let payBtn = bottomPayButton
        payBtn.accessibilityIdentifier = "sdk_paymentpage_button_pay"
        payBtn.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonDisabledBackgroundColor
        payBtn.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonTitleColor, for: .normal)
        payBtn.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonDisabledTitleColor, for: .disabled)
        payBtn.titleLabel?.font = PgType.buttonPrimary
        payBtn.layer.cornerRadius = PgRadius.button
        payBtn.isEnabled = false
        payBtn.translatesAutoresizingMaskIntoConstraints = false
        payBtn.addTarget(self, action: #selector(bottomPayTapped), for: .touchUpInside)

        if NISdk.sharedInstance.shouldShowOrderAmount, let amount = order.amount {
            payBtn.setTitle(String.localizedStringWithFormat("Pay Button Title".localized, amount.getFormattedAmount()), for: .normal)
        } else {
            payBtn.setTitle("Pay".localized, for: .normal)
        }

        let spinner: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(style: .medium)
        } else {
            spinner = UIActivityIndicatorView(style: .white)
        }
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        payBtn.addSubview(spinner)
        bottomPaySpinner = spinner

        let termsLabel = UILabel()
        termsLabel.text = "By clicking Pay terms".localized
        termsLabel.font = PgType.captionDisclaimer
        termsLabel.textColor = PgColors.textMuted
        termsLabel.textAlignment = .center
        termsLabel.numberOfLines = 0
        termsLabel.translatesAutoresizingMaskIntoConstraints = false

        // Apple Pay button — same position as payBtn, hidden initially
        let pkBtn = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        pkBtn.layer.cornerRadius = 8
        pkBtn.isHidden = true
        pkBtn.translatesAutoresizingMaskIntoConstraints = false
        pkBtn.addTarget(self, action: #selector(bottomPayTapped), for: .touchUpInside)
        bottomApplePayButton = pkBtn

        bottomBarView.addSubview(payBtn)
        bottomBarView.addSubview(pkBtn)
        bottomBarView.addSubview(termsLabel)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: bottomBarView.topAnchor),
            separator.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            payBtn.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            payBtn.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 20),
            payBtn.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -20),
            payBtn.heightAnchor.constraint(equalToConstant: PgSize.buttonHeight),

            pkBtn.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            pkBtn.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 20),
            pkBtn.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -20),
            pkBtn.heightAnchor.constraint(equalToConstant: PgSize.buttonHeight),

            spinner.centerYAnchor.constraint(equalTo: payBtn.centerYAnchor),
            spinner.trailingAnchor.constraint(equalTo: payBtn.trailingAnchor, constant: -16),

            termsLabel.topAnchor.constraint(equalTo: payBtn.bottomAnchor, constant: 8),
            termsLabel.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 20),
            termsLabel.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -20),
            termsLabel.bottomAnchor.constraint(equalTo: bottomBarView.bottomAnchor, constant: -8),
        ])
    }

    private func updateBottomPayButton() {
        var enabled: Bool
        switch selectedPaymentOption {
        case .card:
            enabled = isCardFormValid
        case .savedCard(let card):
            let token = card.cardToken ?? ""
            let cvvText = savedCardCvvFields[token]?.text ?? ""
            enabled = !card.recaptureCsc || !cvvText.isEmpty
        case .applePay, .aani, .clickToPay:
            enabled = true
        case .none:
            enabled = false
        }
        // When the user has picked a (non-pay-in-full) Visa installment plan, T&C must be accepted.
        if selectedVisaPlan != nil && !visaTermsAccepted {
            enabled = false
        }
        bottomPayButton.isEnabled = enabled
        bottomPayButton.backgroundColor = enabled
            ? NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor
            : NISdk.sharedInstance.niSdkColors.payButtonDisabledBackgroundColor
        // Pay button label always reflects the original order total, regardless of any
        // Slice or Visa installment plan selection — set once in populateBottomBar().
    }

    private func setupScrollView() {
        scrollView.accessibilityIdentifier = "sdk_paymentpage_scrollview"
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                          leading: view.safeAreaLayoutGuide.leadingAnchor,
                          bottom: bottomBarView.topAnchor,
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

        // 2. Apple Pay section — radio style (if available)
        if availablePaymentOptions.contains(.applePay) {
            let applePaySection = createApplePaySection()
            contentStackView.addArrangedSubview(applePaySection)
        }

        // 3. Card Payment Section (if available)
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

            cardSectionPadding.addSubview(section)
            section.anchor(top: cardSectionPadding.topAnchor, leading: cardSectionPadding.leadingAnchor,
                           bottom: cardSectionPadding.bottomAnchor, trailing: cardSectionPadding.trailingAnchor,
                           padding: UIEdgeInsets(top: 4, left: PgSpacing.pageH, bottom: 4, right: PgSpacing.pageH))

            // Populate saved cards slot inside the card section (between brand icons and "Pay by card")
            if !savedCards.isEmpty {
                for card in savedCards {
                    let row = createSavedCardRow(for: card)
                    section.savedCardsContainer.addArrangedSubview(row)
                }
                section.savedCardsContainer.isHidden = false
            }

            contentStackView.addArrangedSubview(cardSectionPadding)
            cardSection = section
            setupCardInputCallbacks()
        }

        // 4. Other payment options (Click to Pay, Aani)
        let hasOtherOptions = availablePaymentOptions.contains(.clickToPay) || availablePaymentOptions.contains(.aani)
        if hasOtherOptions {
            let otherHeader = createSectionHeader("Or select your payment options".localized)
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

        // Footer excluded from Figma redesign layout
    }

    // MARK: - Merchant Logo Header

    private func createMerchantLogoHeader() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = PgColors.surfaceRow

        // Logo — small, left-aligned
        let sdkBundle = NISdk.sharedInstance.getBundle()
        let logo = NISdk.sharedInstance.merchantLogo
            ?? UIImage(named: "networklogo", in: sdkBundle, compatibleWith: nil)

        let logoView = UIImageView(image: logo)
        logoView.contentMode = .scaleAspectFit
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.accessibilityIdentifier = "sdk_paymentpage_image_merchantLogo"
        container.addSubview(logoView)

        // Amount label — right-aligned below logo
        let amountLabel = UILabel()
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.accessibilityIdentifier = "sdk_paymentpage_label_amount"
        if let amount = order.amount {
            amountLabel.text = amount.getFormattedAmount2Decimal()
        }
        amountLabel.font = PgType.amountSummary
        amountLabel.textColor = PgColors.textPrimary
        amountLabel.textAlignment = .right
        container.addSubview(amountLabel)

        // Order summary row — tappable only when orderItems exist
        let summaryRowStack = UIStackView()
        summaryRowStack.axis = .horizontal
        summaryRowStack.alignment = .center
        summaryRowStack.translatesAutoresizingMaskIntoConstraints = false

        let orderSummaryLabel = UILabel()
        orderSummaryLabel.accessibilityIdentifier = "sdk_paymentpage_label_orderSummary"
        orderSummaryLabel.text = "Order summary".localized
        orderSummaryLabel.font = PgType.bodyRowTitle
        orderSummaryLabel.textColor = PgColors.textMuted
        summaryRowStack.addArrangedSubview(orderSummaryLabel)

        if !orderItems.isEmpty {
            let chevron = UILabel()
            chevron.text = " ▴"
            chevron.font = PgType.bodyRowSubtitle
            chevron.textColor = .gray
            summaryRowStack.addArrangedSubview(chevron)
            orderSummaryChevronLabel = chevron

            let tap = UITapGestureRecognizer(target: self, action: #selector(toggleOrderSummary))
            summaryRowStack.addGestureRecognizer(tap)
            summaryRowStack.isUserInteractionEnabled = true
        }

        container.addSubview(summaryRowStack)

        let detailContainer = UIView()
        detailContainer.translatesAutoresizingMaskIntoConstraints = false
        detailContainer.isHidden = false
        container.addSubview(detailContainer)
        orderSummaryDetailContainer = detailContainer

        if !orderItems.isEmpty {
            let itemsStack = UIStackView()
            itemsStack.axis = .vertical
            itemsStack.spacing = 6
            itemsStack.translatesAutoresizingMaskIntoConstraints = false
            detailContainer.addSubview(itemsStack)
            NSLayoutConstraint.activate([
                itemsStack.topAnchor.constraint(equalTo: detailContainer.topAnchor, constant: 8),
                itemsStack.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor),
                itemsStack.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor),
                itemsStack.bottomAnchor.constraint(equalTo: detailContainer.bottomAnchor, constant: -4),
            ])

            // Column header row
            let headerRow = UIStackView()
            headerRow.axis = .horizontal
            let headerName = UILabel()
            headerName.text = "Item(s)".localized
            headerName.font = PgType.bodyRowSubtitle
            headerName.textColor = PgColors.textMuted
            let headerAmount = UILabel()
            headerAmount.text = "Amount".localized
            headerAmount.font = PgType.bodyRowSubtitle
            headerAmount.textColor = PgColors.textMuted
            headerAmount.textAlignment = .right
            headerRow.addArrangedSubview(headerName)
            headerRow.addArrangedSubview(UIView())
            headerRow.addArrangedSubview(headerAmount)
            itemsStack.addArrangedSubview(headerRow)

            for item in orderItems {
                let row = UIStackView()
                row.axis = .horizontal
                let nameLabel = UILabel()
                nameLabel.text = item.name
                nameLabel.font = PgType.bodyRowTitle
                nameLabel.textColor = PgColors.textSecondary
                let amtLabel = UILabel()
                amtLabel.text = item.amount
                amtLabel.font = PgType.amountRow
                amtLabel.textColor = PgColors.textPrimary
                amtLabel.textAlignment = .right
                row.addArrangedSubview(nameLabel)
                row.addArrangedSubview(UIView()) // spacer
                row.addArrangedSubview(amtLabel)
                itemsStack.addArrangedSubview(row)
            }
        }

        NSLayoutConstraint.activate([
            logoView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            logoView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            logoView.heightAnchor.constraint(equalToConstant: 28),
            logoView.widthAnchor.constraint(lessThanOrEqualToConstant: 120),

            summaryRowStack.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 8),
            summaryRowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),

            amountLabel.centerYAnchor.constraint(equalTo: summaryRowStack.centerYAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: summaryRowStack.trailingAnchor, constant: 8),

            detailContainer.topAnchor.constraint(equalTo: summaryRowStack.bottomAnchor, constant: 4),
            detailContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            detailContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            detailContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])

        return container
    }

    @objc private func toggleOrderSummary() {
        isOrderSummaryExpanded.toggle()
        UIView.animate(withDuration: 0.25) {
            self.orderSummaryChevronLabel?.text = self.isOrderSummaryExpanded ? " ▴" : " ▾"
            self.orderSummaryDetailContainer?.isHidden = !self.isOrderSummaryExpanded
            self.contentStackView.layoutIfNeeded()
        }
    }

    // MARK: - Apple Pay Section (radio style)

    private func createApplePaySection() -> UIView {
        // Section header
        let headerLabel = UILabel()
        headerLabel.text = "Pay with Apple Pay".localized
        headerLabel.font = PgType.headingSection
        headerLabel.textColor = PgColors.textPrimary
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        let headerWrapper = UIView()
        headerWrapper.translatesAutoresizingMaskIntoConstraints = false
        headerWrapper.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerWrapper.heightAnchor.constraint(equalToConstant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: headerWrapper.leadingAnchor),
            headerLabel.centerYAnchor.constraint(equalTo: headerWrapper.centerYAnchor),
        ])

        // Radio button
        let radioButton = RadioButtonView()
        radioButton.isOn = false
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        radioButton.accessibilityIdentifier = "sdk_paymentpage_radio_applePay"
        applePayRadioButton = radioButton

        // Row label
        let rowLabel = UILabel()
        rowLabel.text = "Pay with Apple Pay".localized
        rowLabel.font = PgType.bodyRowTitle
        rowLabel.textColor = PgColors.textPrimary

        // Apple logo on the right
        let appleLogoView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            appleLogoView.image = UIImage(systemName: "apple.logo", withConfiguration: config)
        }
        appleLogoView.tintColor = .black
        appleLogoView.contentMode = .scaleAspectFit
        appleLogoView.translatesAutoresizingMaskIntoConstraints = false
        appleLogoView.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            appleLogoView.widthAnchor.constraint(equalToConstant: 24),
            appleLogoView.heightAnchor.constraint(equalToConstant: 24),
        ])

        // Row stack: radio | label | spacer | Apple logo
        let rowStack = UIStackView(arrangedSubviews: [radioButton, rowLabel, UIView(), appleLogoView])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        // Bordered row container
        let rowContainer = UIView()
        rowContainer.layer.cornerRadius = PgRadius.row
        rowContainer.layer.borderColor = PgColors.borderRow.cgColor
        rowContainer.layer.borderWidth = 1
        rowContainer.backgroundColor = PgColors.surfaceRow
        rowContainer.translatesAutoresizingMaskIntoConstraints = false
        rowContainer.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: rowContainer.topAnchor, constant: 20),
            rowStack.bottomAnchor.constraint(equalTo: rowContainer.bottomAnchor, constant: -20),
            rowStack.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor, constant: PgSpacing.rowPaddingH),
            rowStack.trailingAnchor.constraint(equalTo: rowContainer.trailingAnchor, constant: -PgSpacing.rowPaddingH),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(applePayRadioTapped))
        rowContainer.addGestureRecognizer(tap)
        rowContainer.isUserInteractionEnabled = true

        // Outer container with header + row
        let inner = UIView()
        inner.translatesAutoresizingMaskIntoConstraints = false
        inner.addSubview(headerWrapper)
        inner.addSubview(rowContainer)
        NSLayoutConstraint.activate([
            headerWrapper.topAnchor.constraint(equalTo: inner.topAnchor),
            headerWrapper.leadingAnchor.constraint(equalTo: inner.leadingAnchor),
            headerWrapper.trailingAnchor.constraint(equalTo: inner.trailingAnchor),

            rowContainer.topAnchor.constraint(equalTo: headerWrapper.bottomAnchor, constant: 4),
            rowContainer.leadingAnchor.constraint(equalTo: inner.leadingAnchor),
            rowContainer.trailingAnchor.constraint(equalTo: inner.trailingAnchor),
            rowContainer.bottomAnchor.constraint(equalTo: inner.bottomAnchor, constant: -4),
        ])

        // Padded wrapper
        let paddedContainer = UIView()
        paddedContainer.translatesAutoresizingMaskIntoConstraints = false
        paddedContainer.addSubview(inner)
        inner.anchor(top: paddedContainer.topAnchor, leading: paddedContainer.leadingAnchor,
                     bottom: paddedContainer.bottomAnchor, trailing: paddedContainer.trailingAnchor,
                     padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))

        return paddedContainer
    }

    // MARK: - Section Header

    private func createSectionHeader(_ title: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = PgType.headingSection
        label.textColor = PgColors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 48),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: PgSpacing.pageH),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
        ])

        return container
    }

    // MARK: - Click to Pay Section

    private func createClickToPaySection() -> UIView {
        let sdkBundle = NISdk.sharedInstance.getBundle()

        let radioButton = RadioButtonView()
        radioButton.isOn = false
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        radioButton.accessibilityIdentifier = "sdk_paymentpage_radio_clickToPay"
        clickToPayRadioButton = radioButton

        let titleLabel = UILabel()
        titleLabel.text = "Click to Pay".localized
        titleLabel.font = PgType.bodyRowTitle
        titleLabel.textColor = PgColors.textPrimary

        let logoView = UIImageView(image: UIImage(named: "click_to_pay_payment", in: sdkBundle, compatibleWith: nil))
        logoView.contentMode = .scaleAspectFit
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.widthAnchor.constraint(equalToConstant: PgSize.providerLogoHeight).isActive = true
        logoView.heightAnchor.constraint(equalToConstant: PgSize.providerLogoHeight).isActive = true
        logoView.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [radioButton, titleLabel, UIView(), logoView])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        let tap = UITapGestureRecognizer(target: self, action: #selector(clickToPayRadioTapped))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true

        let rowContainer = UIView()
        rowContainer.layer.cornerRadius = PgRadius.row
        rowContainer.layer.borderColor = PgColors.borderRow.cgColor
        rowContainer.layer.borderWidth = 1
        rowContainer.backgroundColor = PgColors.surfaceRow
        rowContainer.translatesAutoresizingMaskIntoConstraints = false
        rowContainer.addSubview(row)
        row.anchor(top: rowContainer.topAnchor, leading: rowContainer.leadingAnchor,
                   bottom: rowContainer.bottomAnchor, trailing: rowContainer.trailingAnchor,
                   padding: UIEdgeInsets(top: 20, left: PgSpacing.rowPaddingH,
                                        bottom: 20, right: PgSpacing.rowPaddingH))

        let paddedContainer = UIView()
        paddedContainer.translatesAutoresizingMaskIntoConstraints = false
        paddedContainer.addSubview(rowContainer)
        rowContainer.anchor(top: paddedContainer.topAnchor, leading: paddedContainer.leadingAnchor,
                            bottom: paddedContainer.bottomAnchor, trailing: paddedContainer.trailingAnchor,
                            padding: UIEdgeInsets(top: PgSpacing.rowGap, left: PgSpacing.pageH,
                                                  bottom: 0, right: PgSpacing.pageH))
        return paddedContainer
    }

    // MARK: - Aani Section

    private func createAaniSection() -> UIView {
        let sdkBundle = NISdk.sharedInstance.getBundle()

        let radioButton = RadioButtonView()
        radioButton.isOn = false
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        radioButton.accessibilityIdentifier = "sdk_paymentpage_radio_aani"
        aaniRadioButton = radioButton

        let titleLabel = UILabel()
        titleLabel.text = "Pay with Aani".localized
        titleLabel.font = PgType.bodyRowTitle
        titleLabel.textColor = PgColors.textPrimary

        let logoView = UIImageView(image: UIImage(named: "aaniLogo", in: sdkBundle, compatibleWith: nil))
        logoView.contentMode = .scaleAspectFit
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.widthAnchor.constraint(equalToConstant: PgSize.providerLogoHeight).isActive = true
        logoView.heightAnchor.constraint(equalToConstant: PgSize.providerLogoHeight).isActive = true
        logoView.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [radioButton, titleLabel, UIView(), logoView])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        let tap = UITapGestureRecognizer(target: self, action: #selector(aaniRadioTapped))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true

        let rowContainer = UIView()
        rowContainer.layer.cornerRadius = PgRadius.row
        rowContainer.layer.borderColor = PgColors.borderRow.cgColor
        rowContainer.layer.borderWidth = 1
        rowContainer.backgroundColor = PgColors.surfaceRow
        rowContainer.translatesAutoresizingMaskIntoConstraints = false
        rowContainer.addSubview(row)
        row.anchor(top: rowContainer.topAnchor, leading: rowContainer.leadingAnchor,
                   bottom: rowContainer.bottomAnchor, trailing: rowContainer.trailingAnchor,
                   padding: UIEdgeInsets(top: 20, left: PgSpacing.rowPaddingH,
                                        bottom: 20, right: PgSpacing.rowPaddingH))

        let paddedContainer = UIView()
        paddedContainer.translatesAutoresizingMaskIntoConstraints = false
        paddedContainer.addSubview(rowContainer)
        rowContainer.anchor(top: paddedContainer.topAnchor, leading: paddedContainer.leadingAnchor,
                            bottom: paddedContainer.bottomAnchor, trailing: paddedContainer.trailingAnchor,
                            padding: UIEdgeInsets(top: PgSpacing.rowGap, left: PgSpacing.pageH,
                                                  bottom: 0, right: PgSpacing.pageH))
        return paddedContainer
    }

    private func createSavedCardRow(for card: SavedCard) -> UIView {
        let sdkBundle = NISdk.sharedInstance.getBundle()
        let token = card.cardToken ?? ""

        // Radio button
        let radio = RadioButtonView()
        radio.isOn = false
        radio.translatesAutoresizingMaskIntoConstraints = false
        radio.accessibilityIdentifier = "sdk_paymentpage_radio_savedCard_\(card.maskedPan?.suffix(4) ?? "")"
        savedCardRadioButtons[token] = radio
        NSLayoutConstraint.activate([
            radio.widthAnchor.constraint(equalToConstant: PgSize.radioOuter),
            radio.heightAnchor.constraint(equalToConstant: PgSize.radioOuter),
        ])

        // Card logo in a small bordered box
        let logoName = cardLogoName(for: card.scheme ?? "")
        let logoImg = UIImageView(image: UIImage(named: logoName, in: sdkBundle, compatibleWith: nil))
        logoImg.contentMode = .scaleAspectFit
        logoImg.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoImg.widthAnchor.constraint(equalToConstant: 32),
            logoImg.heightAnchor.constraint(equalToConstant: 20),
        ])
        let logoBox = UIView()
        logoBox.layer.borderColor = PgColors.borderRow.cgColor
        logoBox.layer.borderWidth = 1
        logoBox.layer.cornerRadius = 6
        logoBox.translatesAutoresizingMaskIntoConstraints = false
        logoBox.addSubview(logoImg)
        NSLayoutConstraint.activate([
            logoImg.topAnchor.constraint(equalTo: logoBox.topAnchor, constant: 5),
            logoImg.bottomAnchor.constraint(equalTo: logoBox.bottomAnchor, constant: -5),
            logoImg.leadingAnchor.constraint(equalTo: logoBox.leadingAnchor, constant: 6),
            logoImg.trailingAnchor.constraint(equalTo: logoBox.trailingAnchor, constant: -6),
        ])

        let last4 = String((card.maskedPan ?? "").suffix(4))

        // Line 1: "ending in XXXX"
        let line1 = UILabel()
        line1.text = "ending in \(last4)"
        line1.font = PgType.bodyRowTitle
        line1.textColor = PgColors.textPrimary
        line1.numberOfLines = 1

        // Line 2: name + expiry
        let nameLabel = UILabel()
        nameLabel.text = card.cardholderName ?? ""
        nameLabel.font = PgType.bodyRowSubtitle
        nameLabel.textColor = PgColors.textMuted
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let expiryLabel = UILabel()
        expiryLabel.text = formatSavedCardExpiry(card.expiry ?? "")
        expiryLabel.font = PgType.bodyRowSubtitle
        expiryLabel.textColor = PgColors.textMuted
        expiryLabel.setContentHuggingPriority(.required, for: .horizontal)
        expiryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let line2Stack = UIStackView(arrangedSubviews: [nameLabel, expiryLabel])
        line2Stack.axis = .horizontal
        line2Stack.spacing = 8
        line2Stack.alignment = .center

        // Vertical info column
        let infoStack = UIStackView(arrangedSubviews: [line1, line2Stack])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        infoStack.alignment = .fill
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        infoStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Build row — inline CVV only for recaptureCsc cards
        var rowSubviews: [UIView] = [radio, logoBox, infoStack]
        if card.recaptureCsc {
            let cvvView = createInlineCvvField(for: card)
            cvvView.isHidden = true
            savedCardCvvContainers[token] = cvvView
            rowSubviews.append(cvvView)
        }

        let rowStack = UIStackView(arrangedSubviews: rowSubviews)
        rowStack.axis = .horizontal
        rowStack.spacing = 10
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        // Row container — tap gesture + selection background
        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(rowStack)
        rowStack.anchor(top: container.topAnchor, leading: container.leadingAnchor,
                        bottom: container.bottomAnchor, trailing: container.trailingAnchor,
                        padding: UIEdgeInsets(top: 12, left: PgSpacing.rowPaddingH, bottom: 12, right: PgSpacing.rowPaddingH))

        let tap = UITapGestureRecognizer(target: self, action: #selector(savedCardRowTapped(_:)))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        container.tag = savedCards.firstIndex(where: { $0.cardToken == token }) ?? 0
        savedCardRowContainers[token] = container

        return container
    }

    private func createInlineCvvField(for card: SavedCard) -> UIView {
        let token = card.cardToken ?? ""

        let field = UITextField()
        field.placeholder = "•••"
        field.keyboardType = .numberPad
        field.isSecureTextEntry = true
        field.borderStyle = .none
        field.font = PgType.bodyRowTitle
        field.textColor = PgColors.textPrimary
        field.translatesAutoresizingMaskIntoConstraints = false
        field.accessibilityIdentifier = "sdk_paymentpage_field_savedCardCvv"
        field.addTarget(self, action: #selector(savedCardCvvChanged(_:)), for: .editingChanged)
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [spacer, done]
        field.inputAccessoryView = toolbar
        savedCardCvvFields[token] = field

        let iconView = UIImageView()
        if #available(iOS 13.0, *) {
            iconView.image = UIImage(systemName: "creditcard")
        }
        iconView.tintColor = PgColors.textMuted
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 14),
        ])

        let inner = UIStackView(arrangedSubviews: [field, iconView])
        inner.axis = .horizontal
        inner.spacing = 4
        inner.alignment = .center
        inner.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.borderColor = PgColors.borderInput.cgColor
        container.layer.borderWidth = 1
        container.layer.cornerRadius = 8
        container.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            inner.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            inner.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            inner.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            container.widthAnchor.constraint(equalToConstant: 84),
        ])

        return container
    }

    // Converts YYYY-MM → MM/YY
    private func formatSavedCardExpiry(_ expiry: String) -> String {
        let parts = expiry.split(separator: "-")
        guard parts.count == 2 else { return expiry }
        let year = String(parts[0].suffix(2))
        let month = String(parts[1])
        return "\(month)/\(year)"
    }

    private func formatSchemeName(_ scheme: String) -> String {
        switch scheme.uppercased() {
        case "MASTERCARD": return "Mastercard"
        case "VISA": return "Visa"
        case "AMERICAN_EXPRESS": return "Amex"
        case "DINERS_CLUB_INTERNATIONAL": return "Diners"
        case "JCB": return "JCB"
        case "DISCOVER": return "Discover"
        case "MADA": return "Mada"
        default: return scheme.prefix(1).uppercased() + scheme.dropFirst().lowercased()
        }
    }

    /// Detects the card brand from the BIN prefix as the user types, before the PAN is long enough
    /// for `Pan.getCardProvider()` (which requires a fully-valid number). Returns nil when the prefix
    /// doesn't match any known scheme.
    private func detectBrandFromPrefix(_ pan: String) -> CardProvider? {
        let digits = pan.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }

        if digits.first == "4" { return .visa }

        guard digits.count >= 2 else { return nil }
        let two = String(digits.prefix(2))
        let twoInt = Int(two) ?? 0

        if (twoInt >= 51 && twoInt <= 55) || (twoInt >= 22 && twoInt <= 27) {
            return .masterCard
        }
        if two == "34" || two == "37" { return .americanExpress }
        if two == "36" || two == "38" || two == "39" { return .dinersClubInternational }
        if two == "30", digits.count >= 3,
           let third = digits.dropFirst(2).first, "012345".contains(third) {
            return .dinersClubInternational
        }
        if two == "35" { return .jcb }
        if digits.hasPrefix("2131") || digits.hasPrefix("1800") { return .jcb }
        if digits.hasPrefix("6011") || two == "65" { return .discover }
        if digits.count >= 3, let n = Int(digits.prefix(3)), n >= 644 && n <= 649 {
            return .discover
        }
        return nil
    }

    private func updateCardBrandIcon(forPan pan: String) {
        guard let cardSection = cardSection else { return }
        let provider = detectBrandFromPrefix(pan)
        let logoName: String?
        switch provider {
        case .visa: logoName = "visalogo"
        case .masterCard: logoName = "mastercardlogo"
        case .americanExpress: logoName = "amexlogo"
        case .dinersClubInternational: logoName = "dinerslogo"
        case .jcb: logoName = "jcblogo"
        case .discover: logoName = "discoverlogo"
        case .mada: logoName = "madalogo"
        default: logoName = nil
        }
        cardSection.updateCardBrand(logoName: logoName)
    }

    private func cardLogoName(for scheme: String) -> String {
        switch scheme.uppercased() {
        case "VISA": return "visalogo"
        case "MASTERCARD": return "mastercardlogo"
        case "AMERICAN_EXPRESS": return "amexlogo"
        case "DINERS_CLUB_INTERNATIONAL": return "dinerslogo"
        case "JCB": return "jcblogo"
        case "DISCOVER": return "discoverlogo"
        case "MADA": return "madalogo"
        default: return "defaultlogo"
        }
    }

    @objc private func savedCardRowTapped(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag, index < savedCards.count else { return }
        let card = savedCards[index]
        // If this card is already selected, ignore the tap. The row's tap gesture also fires
        // when the user taps inside the inline CVV field; previously this would deselect the
        // card and re-fire the eligibility check on the next reselection.
        if case .savedCard(let current) = selectedPaymentOption, current.cardToken == card.cardToken {
            return
        }
        selectPaymentOption(.savedCard(card))
    }

    @objc private func savedCardCvvChanged(_ sender: UITextField) {
        if case .savedCard(let card) = selectedPaymentOption, card.recaptureCsc {
            updateBottomPayButton()
        }
    }

    // MARK: - Card Input Callbacks

    private func setupCardInputCallbacks() {
        guard let cardSection = cardSection else { return }

        cardSection.onCardNumberChanged = { [weak self] text in
            self?.pan.value = text
            self?.updateCardBrandIcon(forPan: text)
            self?.maybeCheckSliceEligibility()
        }
        cardSection.onExpiryMonthChanged = { [weak self] text in
            self?.expiryDate.month = text
        }
        cardSection.onExpiryYearChanged = { [weak self] text in
            self?.expiryDate.year = text
            self?.maybeCheckSliceEligibility()
        }
        cardSection.onCvvChanged = { [weak self] text in
            self?.cvv.value = text
        }
        cardSection.onNameChanged = { [weak self] text in
            self?.cardHolderName.value = text
        }
        cardSection.onFormValidityChanged = { [weak self] isValid in
            self?.isCardFormValid = isValid
            if self?.selectedPaymentOption == .card {
                self?.updateBottomPayButton()
            }
        }
    }

    private func maybeCheckSliceEligibility() {
        guard let panValue = pan.value, pan.validate(),
              expiryDate.validate(),
              let month = expiryDate.month, month.count == 2,
              let year = expiryDate.year, year.count == 2 else { return }

        if let allowed = allowedCardProviders {
            let provider = pan.getCardProvider()
            guard provider != .unknown, allowed.contains(provider) else { return }
        }

        let expiry = "20\(year)-\(month)"
        let key = "\(panValue)|\(expiry)"

        // Single key prevents duplicate eligibility round-trips for the same (pan, expiry).
        // Whenever the key changes, every prior installment selection is cleared and both
        // Slice (priority) and Visa (fallback) are re-evaluated from scratch.
        guard key != lastSliceCheckKey else { return }
        lastSliceCheckKey = key
        lastVisCheckKey = nil

        selectedSliceOffer = nil
        hideSliceOffers()
        hideVisaInstallments()
        selectedVisaPlan = nil
        visaTermsAccepted = false

        // Slice path: fire if a callback is wired; on empty/error/missing-link the wrapper in
        // PaymentViewController completes with `[]`, which here trips the Visa fallback.
        if let checkSlice = onCheckSliceEligibility {
            cardSection?.showSliceLoader()
            checkSlice(panValue, expiry, false) { [weak self] offers in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.cardSection?.hideSliceLoader()
                    if !offers.isEmpty {
                        self.showSliceOffers(offers)
                    } else {
                        self.maybeCheckVisEligibility(cardTokenOrPan: panValue, key: key)
                    }
                }
            }
        } else {
            // No Slice callback at all — go straight to Vis.
            maybeCheckVisEligibility(cardTokenOrPan: panValue, key: key)
        }
    }

    private func maybeCheckVisEligibility(cardTokenOrPan: String, key: String, isSavedToken: Bool = false) {
        guard let checkVis = onCheckVisEligibility else { return }
        // For manual entry we can validate the scheme via Pan.getCardProvider; for saved cards
        // the caller has already verified the scheme on its end.
        if !isSavedToken {
            guard pan.getCardProvider() == .visa else { return }
        }
        guard key != lastVisCheckKey else { return }
        lastVisCheckKey = key

        checkVis(cardTokenOrPan, isSavedToken) { [weak self] plans in
            guard let self = self else { return }
            guard let plans = plans, !plans.matchedPlans.isEmpty else {
                self.hideVisaInstallments()
                return
            }
            self.showVisaInstallments(plans)
        }
    }

    /// Fires Slice + Visa Installments eligibility for a saved card. Slice runs with the saved
    /// card's token in the API's `cardToken` field (not `pan`, which the endpoint validates as
    /// digits-only). On Slice empty/error we fall back to Vis (only for Visa-scheme saved cards).
    private func maybeCheckVisEligibilityForSavedCard(_ card: SavedCard) {
        guard let token = card.cardToken, !token.isEmpty else { return }
        guard let cardExpiry = card.expiry, !cardExpiry.isEmpty else { return }

        let key = "saved|\(token)"
        guard key != lastSliceCheckKey else { return }
        lastSliceCheckKey = key
        lastVisCheckKey = nil

        selectedSliceOffer = nil
        hideSliceOffers()
        hideVisaInstallments()
        selectedVisaPlan = nil
        visaTermsAccepted = false

        let isVisa = (card.scheme ?? "").uppercased() == "VISA"

        if let checkSlice = onCheckSliceEligibility {
            cardSection?.showSliceLoader()
            checkSlice(token, cardExpiry, true) { [weak self] offers in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.cardSection?.hideSliceLoader()
                    if !offers.isEmpty {
                        self.showSliceOffers(offers)
                    } else if isVisa {
                        self.maybeCheckVisEligibility(cardTokenOrPan: token, key: key, isSavedToken: true)
                    }
                }
            }
        } else if isVisa {
            maybeCheckVisEligibility(cardTokenOrPan: token, key: key, isSavedToken: true)
        }
    }

    private func showSliceOffers(_ offers: [SliceOffer]) {
        guard let cardSection = cardSection else { return }
        sliceInstallmentView?.removeFromSuperview()

        let sliceView = SliceInstallmentUIView(offers: offers) { [weak self] offer in
            self?.selectedSliceOffer = offer
        }
        sliceView.onSizeChange = { [weak self] in
            UIView.animate(withDuration: 0.2) {
                self?.cardSection?.sliceInstallmentContainer.invalidateIntrinsicContentSize()
                self?.view.layoutIfNeeded()
            }
        }
        sliceInstallmentView = sliceView
        cardSection.showSliceInstallmentView(sliceView)
    }

    private func hideSliceOffers() {
        sliceInstallmentView?.removeFromSuperview()
        sliceInstallmentView = nil
        cardSection?.hideSliceInstallmentContainer()
    }

    private func showVisaInstallments(_ plans: VisaPlans) {
        guard let cardSection = cardSection else { return }
        visaInstallmentView?.removeFromSuperview()
        visaPlansResponse = plans
        selectedVisaPlan = nil
        visaTermsAccepted = false

        let view = VisaInstallmentInlineView(plans: plans.matchedPlans, payInFullAmount: order.amount)
        view.onSizeChange = { [weak self] in
            UIView.animate(withDuration: 0.2) {
                self?.cardSection?.visaInstallmentContainer.invalidateIntrinsicContentSize()
                self?.view.layoutIfNeeded()
            }
        }
        view.onSelectionChanged = { [weak self] plan, termsAccepted in
            guard let self = self else { return }
            self.selectedVisaPlan = plan
            self.visaTermsAccepted = termsAccepted
            self.updateBottomPayButton()
        }
        visaInstallmentView = view
        cardSection.showVisaInstallmentView(view)
    }

    private func hideVisaInstallments() {
        visaInstallmentView?.removeFromSuperview()
        visaInstallmentView = nil
        visaPlansResponse = nil
        selectedVisaPlan = nil
        visaTermsAccepted = false
        cardSection?.hideVisaInstallmentContainer()
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

    private func payCardAction() {
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
                if let offer = selectedSliceOffer {
                    paymentRequest.sliceRequest = SliceRequest(period: offer.period,
                                                               rate: offer.rate,
                                                               fee: offer.fee)
                }
                if let plan = selectedVisaPlan {
                    let iso2Code = Locale.iso639_2LanguageCode ?? ""
                    let acceptedTC = plan.termsAndConditions?.first { $0.languageCode == iso2Code }
                                       ?? plan.termsAndConditions?.first
                    paymentRequest.visaRequest = VisaRequest(
                        planSelectionIndicator: true,
                        acceptedTAndCVersion: acceptedTC?.version,
                        vPlanId: plan.vPlanID
                    )
                } else if visaPlansResponse != nil {
                    // The inline Vis selector ran but the user opted out (Pay in full / no plan).
                    // Send an opt-out VisaRequest so PaymentViewController skips the legacy
                    // post-tap getVisaPlans + full-screen prompt.
                    paymentRequest.visaRequest = VisaRequest(
                        planSelectionIndicator: false,
                        acceptedTAndCVersion: nil,
                        vPlanId: nil
                    )
                }
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
        // Toggle off if tapping the already-selected option
        if selectedPaymentOption == option {
            selectedPaymentOption = nil
            selectedSavedCard = nil
            applePayRadioButton?.isOn = false
            cardSection?.setSelected(false)
            cardSection?.setExpanded(false, animated: true)
            clickToPayRadioButton?.isOn = false
            aaniRadioButton?.isOn = false
            savedCardRadioButtons.values.forEach { $0.isOn = false }
            savedCardCvvContainers.values.forEach { $0.isHidden = true }
            savedCardRowContainers.values.forEach {
                $0.backgroundColor = .clear
                $0.layer.cornerRadius = 0
                $0.layer.borderWidth = 0
                $0.clipsToBounds = false
            }
            // Clear any installment selectors that were tied to the previous selection.
            hideVisaInstallments()
            hideSliceOffers()
            lastVisCheckKey = nil
            lastSliceCheckKey = nil
            applyBottomButtonStyle(forApplePay: false)
            updateBottomPayButton()
            return
        }

        selectedPaymentOption = option

        // Deselect everything first
        applePayRadioButton?.isOn = false
        cardSection?.setSelected(false)
        cardSection?.setExpanded(false, animated: true)
        clickToPayRadioButton?.isOn = false
        aaniRadioButton?.isOn = false
        savedCardRadioButtons.values.forEach { $0.isOn = false }
        savedCardCvvContainers.values.forEach { $0.isHidden = true }
        savedCardRowContainers.values.forEach {
            $0.backgroundColor = .clear
            $0.layer.cornerRadius = 0
            $0.layer.borderWidth = 0
            $0.clipsToBounds = false
        }
        selectedSavedCard = nil

        switch option {
        case .applePay:
            applePayRadioButton?.isOn = true
            // Selection moved away from card — drop any installment selectors.
            hideVisaInstallments()
            hideSliceOffers()
            lastVisCheckKey = nil
            lastSliceCheckKey = nil
            applyBottomButtonStyle(forApplePay: true)
        case .card:
            cardSection?.setSelected(true)
            cardSection?.setExpanded(true, animated: true)
            // Switching from saved-card → manual: clear stale saved-card Vis state so the
            // manual entry can re-evaluate from PAN/expiry input.
            hideVisaInstallments()
            lastVisCheckKey = nil
            applyBottomButtonStyle(forApplePay: false)
        case .savedCard(let card):
            selectedSavedCard = card
            let token = card.cardToken ?? ""
            savedCardRadioButtons[token]?.isOn = true
            if let rowContainer = savedCardRowContainers[token] {
                rowContainer.backgroundColor = PgColors.surfaceRow
                rowContainer.layer.cornerRadius = PgRadius.row
                rowContainer.layer.borderColor = PgColors.borderRow.cgColor
                rowContainer.layer.borderWidth = 1
                rowContainer.clipsToBounds = true
            }
            if card.recaptureCsc {
                savedCardCvvContainers[token]?.isHidden = false
                savedCardCvvFields[token]?.becomeFirstResponder()
            }
            applyBottomButtonStyle(forApplePay: false)
            // Fire Visa Installments eligibility for this saved card.
            maybeCheckVisEligibilityForSavedCard(card)
        case .clickToPay:
            clickToPayRadioButton?.isOn = true
            hideVisaInstallments()
            hideSliceOffers()
            lastVisCheckKey = nil
            lastSliceCheckKey = nil
            applyBottomButtonStyle(forApplePay: false)
        case .aani:
            aaniRadioButton?.isOn = true
            hideVisaInstallments()
            hideSliceOffers()
            lastVisCheckKey = nil
            lastSliceCheckKey = nil
            applyBottomButtonStyle(forApplePay: false)
        }

        updateBottomPayButton()
    }

    private func applyBottomButtonStyle(forApplePay: Bool) {
        bottomPayButton.isHidden = forApplePay
        bottomApplePayButton?.isHidden = !forApplePay
    }

    // MARK: - Actions

    @objc private func applePayRadioTapped() {
        selectPaymentOption(.applePay)
    }

    @objc private func bottomPayTapped() {
        switch selectedPaymentOption {
        case .card:
            payCardAction()
        case .applePay:
            onApplePayTapped?()
        case .savedCard(let card):
            let token = card.cardToken ?? ""
            let cvv = savedCardCvvFields[token]?.text
            let visaRequest: VisaRequest? = {
                if let plan = selectedVisaPlan {
                    let iso2Code = Locale.iso639_2LanguageCode ?? ""
                    let acceptedTC = plan.termsAndConditions?.first { $0.languageCode == iso2Code }
                                       ?? plan.termsAndConditions?.first
                    return VisaRequest(
                        planSelectionIndicator: true,
                        acceptedTAndCVersion: acceptedTC?.version,
                        vPlanId: plan.vPlanID
                    )
                }
                if visaPlansResponse != nil {
                    // Inline Vis ran but user opted out — send opt-out so PaymentViewController
                    // skips the legacy post-tap full-screen Vis prompt.
                    return VisaRequest(
                        planSelectionIndicator: false,
                        acceptedTAndCVersion: nil,
                        vPlanId: nil
                    )
                }
                return nil
            }()
            paymentInProgress = true
            onMakeSavedCardPayment?(card, cvv?.isEmpty == false ? cvv : nil, visaRequest)
        case .aani:
            onAaniTapped?()
        case .clickToPay:
            onClickToPayTapped?()
        case .none:
            break
        }
    }

    @objc private func clickToPayRadioTapped() {
        selectPaymentOption(.clickToPay)
    }

    @objc private func aaniRadioTapped() {
        selectPaymentOption(.aani)
    }

    // MARK: - Navigation

    /// Extends the F5F9FC merchant-header background up to the top of the view so the area
    /// behind the status bar / safe-area inset matches the order summary section.
    private func setupHeaderBackground() {
        let topBg = UIView()
        topBg.backgroundColor = PgColors.surfaceRow
        topBg.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(topBg, at: 0)
        NSLayoutConstraint.activate([
            topBg.topAnchor.constraint(equalTo: view.topAnchor),
            topBg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBg.bottomAnchor.constraint(equalTo: scrollView.topAnchor),
        ])
    }

    private func setupCancelButton() {
        self.parent?.navigationController?.setNavigationBarHidden(false, animated: false)
        self.parent?.navigationItem.title = nil

        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = PgColors.surfaceRow
            appearance.shadowColor = .clear
            let plainButtonAppearance = UIBarButtonItemAppearance(style: .plain)
            plainButtonAppearance.normal.backgroundImage = UIImage()
            plainButtonAppearance.highlighted.backgroundImage = UIImage()
            appearance.buttonAppearance = plainButtonAppearance
            appearance.doneButtonAppearance = plainButtonAppearance
            self.parent?.navigationController?.navigationBar.standardAppearance = appearance
            self.parent?.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            self.parent?.navigationController?.navigationBar.barTintColor = PgColors.surfaceRow
            self.parent?.navigationController?.navigationBar.isTranslucent = false
        }

        if #available(iOS 13.0, *) {
            let xImage = UIImage(systemName: "xmark",
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))?
                .withRenderingMode(.alwaysTemplate)
            let button = UIButton(type: .custom)
            button.setImage(xImage, for: .normal)
            button.tintColor = PgColors.textPrimary
            button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            button.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
            button.accessibilityIdentifier = "sdk_paymentpage_button_cancel"
            let closeButton = UIBarButtonItem(customView: button)
            closeButton.accessibilityIdentifier = "sdk_paymentpage_button_cancel"
            self.parent?.navigationItem.rightBarButtonItem = closeButton
        } else {
            let closeButton = UIBarButtonItem(title: "✕", style: .plain,
                                              target: self, action: #selector(cancelAction))
            closeButton.tintColor = PgColors.textPrimary
            closeButton.accessibilityIdentifier = "sdk_paymentpage_button_cancel"
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

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
