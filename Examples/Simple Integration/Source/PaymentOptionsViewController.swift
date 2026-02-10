//
//  PaymentOptionsViewController.swift
//  Simple Integration
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation
import UIKit
import NISdk
import PassKit

protocol PaymentOptionsDelegate: AnyObject {
    func didSelectCardPayment(orderResponse: OrderResponse)
    func didSelectAaniPayment(orderResponse: OrderResponse)
    func didSelectClickToPay(orderResponse: OrderResponse)
    func didSelectApplePay(orderResponse: OrderResponse)
    func didSelectSavedCard(orderResponse: OrderResponse, savedCard: SavedCard, cvv: String?)
    func didCancelPaymentOptions()
}

class PaymentOptionsViewController: UIViewController {

    private let orderResponse: OrderResponse
    private let savedCard: SavedCard?
    weak var delegate: PaymentOptionsDelegate?

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        return stack
    }()

    init(orderResponse: OrderResponse, savedCard: SavedCard?, delegate: PaymentOptionsDelegate) {
        self.orderResponse = orderResponse
        self.savedCard = savedCard
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addPaymentButtons()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Select Payment Method"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Setup content stack inside scroll view
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        // Order summary label
        let amountLabel = UILabel()
        amountLabel.text = "Amount: \(orderResponse.formattedAmount ?? "")"
        amountLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        amountLabel.textAlignment = .center
        contentStack.addArrangedSubview(amountLabel)

        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        contentStack.addArrangedSubview(spacer)
    }

    private func addPaymentButtons() {
        let paymentMethods = orderResponse.paymentMethods
        let walletRaw = paymentMethods?.wallet?.map { $0.rawValue } ?? []
        let apmList: [String] = []
        let cardList = paymentMethods?.card ?? []

        // Card Payment
        if !cardList.isEmpty {
            let button = makePaymentButton(
                title: "Pay by Card",
                subtitle: "Visa, Mastercard, Amex",
                iconName: "creditcard.fill"
            )
            button.addTarget(self, action: #selector(cardPaymentTapped), for: .touchUpInside)
            contentStack.addArrangedSubview(button)
        }

        // Click to Pay
        if walletRaw.contains("VISA_CLICK_TO_PAY") {
            let button = makePaymentButton(
                title: "Click to Pay",
                subtitle: "Fast checkout with Visa",
                iconName: "bolt.fill"
            )
            button.addTarget(self, action: #selector(clickToPayTapped), for: .touchUpInside)
            contentStack.addArrangedSubview(button)
        }

        // Aani Pay
        if apmList.contains("AANI") {
            let button = makePaymentButton(
                title: "Aani Pay",
                subtitle: "Instant bank transfer",
                iconName: "building.columns.fill"
            )
            button.addTarget(self, action: #selector(aaniPayTapped), for: .touchUpInside)
            contentStack.addArrangedSubview(button)
        }

        // Apple Pay
        if NISdk.sharedInstance.deviceSupportsApplePay() && walletRaw.contains("DIRECT_APPLE_PAY") {
            let applePayButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
            applePayButton.addTarget(self, action: #selector(applePayTapped), for: .touchUpInside)
            applePayButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            contentStack.addArrangedSubview(applePayButton)
        }

        // Saved Card
        if let savedCard = savedCard {
            let maskedPan = savedCard.maskedPan ?? "****"
            let lastFour = String(maskedPan.suffix(4))
            let button = makePaymentButton(
                title: "Saved Card •••• \(lastFour)",
                subtitle: savedCard.scheme ?? "Card",
                iconName: "wallet.pass.fill"
            )
            button.addTarget(self, action: #selector(savedCardTapped), for: .touchUpInside)
            contentStack.addArrangedSubview(button)
        }
    }

    private func makePaymentButton(title: String, subtitle: String, iconName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .label
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false

        let hStack = UIStackView(arrangedSubviews: [icon, textStack])
        hStack.axis = .horizontal
        hStack.spacing = 14
        hStack.alignment = .center
        hStack.isUserInteractionEnabled = false
        hStack.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            hStack.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])

        return button
    }

    // MARK: - Actions

    @objc private func cardPaymentTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didSelectCardPayment(orderResponse: self.orderResponse)
        }
    }

    @objc private func clickToPayTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didSelectClickToPay(orderResponse: self.orderResponse)
        }
    }

    @objc private func aaniPayTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didSelectAaniPayment(orderResponse: self.orderResponse)
        }
    }

    @objc private func applePayTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didSelectApplePay(orderResponse: self.orderResponse)
        }
    }

    @objc private func savedCardTapped() {
        guard let savedCard = savedCard else { return }
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didSelectSavedCard(orderResponse: self.orderResponse, savedCard: savedCard, cvv: nil)
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.didCancelPaymentOptions()
        }
    }
}
