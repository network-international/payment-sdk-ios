//
//  OrderHeaderView.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import UIKit

class OrderHeaderView: UIView {

    private let order: OrderResponse
    private var isExpanded = false
    private let chevronLabel = UILabel()
    private let summaryDetailContainer = UIView()

    init(order: OrderResponse) {
        self.order = order
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = NISdk.sharedInstance.niSdkColors.payPageBackgroundColor

        let topRow = createTopRow()
        let bottomRow = createSummaryRow()

        summaryDetailContainer.translatesAutoresizingMaskIntoConstraints = false
        summaryDetailContainer.isHidden = true

        let stack = UIStackView(arrangedSubviews: [topRow, bottomRow, summaryDetailContainer])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    private func createTopRow() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let flagLabel = UILabel()
        flagLabel.text = currencyFlag(for: order.amount?.currencyCode)
        flagLabel.font = UIFont.systemFont(ofSize: 20)
        flagLabel.translatesAutoresizingMaskIntoConstraints = false

        let amountLabel = UILabel()
        amountLabel.text = order.amount?.getFormattedAmount() ?? ""
        amountLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        amountLabel.textColor = NISdk.sharedInstance.niSdkColors.payPageLabelColor
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        let currencyPill = PaddedLabel()
        currencyPill.text = "+7 currencies available".localized
        currencyPill.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        currencyPill.textColor = UIColor.darkGray
        currencyPill.backgroundColor = UIColor(hexString: "#f0f0f0")
        currencyPill.layer.cornerRadius = 10
        currencyPill.layer.masksToBounds = true
        currencyPill.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(flagLabel)
        container.addSubview(amountLabel)
        container.addSubview(currencyPill)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 30),
            flagLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            flagLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            amountLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 8),
            amountLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            currencyPill.leadingAnchor.constraint(equalTo: amountLabel.trailingAnchor, constant: 8),
            currencyPill.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            currencyPill.heightAnchor.constraint(equalToConstant: 20),
        ])

        return container
    }

    private func createSummaryRow() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let summaryButton = UIButton(type: .system)
        summaryButton.setTitle("Order summary".localized, for: .normal)
        summaryButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        summaryButton.setTitleColor(UIColor.gray, for: .normal)
        summaryButton.contentHorizontalAlignment = .leading
        summaryButton.translatesAutoresizingMaskIntoConstraints = false
        summaryButton.addTarget(self, action: #selector(toggleSummary), for: .touchUpInside)

        chevronLabel.text = "▾"
        chevronLabel.font = UIFont.systemFont(ofSize: 12)
        chevronLabel.textColor = .gray
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        let rightAmountLabel = UILabel()
        rightAmountLabel.text = order.amount?.getFormattedAmount() ?? ""
        rightAmountLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        rightAmountLabel.textColor = NISdk.sharedInstance.niSdkColors.payPageLabelColor
        rightAmountLabel.textAlignment = .right
        rightAmountLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(summaryButton)
        container.addSubview(chevronLabel)
        container.addSubview(rightAmountLabel)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 30),
            summaryButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            summaryButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronLabel.leadingAnchor.constraint(equalTo: summaryButton.trailingAnchor, constant: 4),
            chevronLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rightAmountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightAmountLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }

    @objc private func toggleSummary() {
        isExpanded.toggle()
        UIView.animate(withDuration: 0.25) {
            self.chevronLabel.text = self.isExpanded ? "▴" : "▾"
            self.summaryDetailContainer.isHidden = !self.isExpanded
            self.superview?.layoutIfNeeded()
        }
    }

    private func currencyFlag(for code: String?) -> String {
        switch code {
        case "AED": return "🇦🇪"
        case "SAR": return "🇸🇦"
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        default: return "💳"
        }
    }
}

private class PaddedLabel: UILabel {
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 16, height: size.height + 4)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: 8, dy: 2))
    }
}
