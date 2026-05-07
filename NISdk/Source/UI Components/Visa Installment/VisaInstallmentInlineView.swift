//
//  VisaInstallmentInlineView.swift
//  NISdk
//
//  Inline Visa installment selector rendered inside the unified payment page card section.
//  Mirrors the design: "Eligible for instalments" header, horizontal pill row
//  (Pay in full / N months / …), monthly rate + processing fees, total summary,
//  T&C checkbox, "Instalment enabled by VISA" footer.
//

import UIKit

final class VisaInstallmentInlineView: UIView {

    var onSizeChange: (() -> Void)?
    var onSelectionChanged: ((MatchedPlan?, Bool) -> Void)?

    private let plans: [MatchedPlan]
    private let payInFullAmount: Amount?
    private var selectedIndex = 0 // 0 == Pay in full, 1..N == plans[i-1]
    private var termsAccepted = false

    private let mainStack = UIStackView()
    private var pillButtons: [UIButton] = []
    private let detailContainer = UIStackView()
    private let monthlyAmountLabel = UILabel()
    private let monthlyForLabel = UILabel()
    private let monthlyRateLabel = UILabel()
    private let processingFeesLabel = UILabel()
    private let totalLabel = UILabel()
    private let termsRow = UIStackView()
    private let termsCheckbox = UIButton(type: .system)
    private let termsTextLabel = UILabel()

    init(plans: [MatchedPlan], payInFullAmount: Amount?) {
        self.plans = plans
        self.payInFullAmount = payInFullAmount
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(makeHeader())
        mainStack.addArrangedSubview(makePillRow())
        mainStack.addArrangedSubview(makeDetailSection())
        mainStack.addArrangedSubview(makeTermsRow())
        mainStack.addArrangedSubview(makeFooter())
        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
        refreshPillAppearance()
        refreshDetailVisibility()
    }

    // MARK: - Header

    private func makeHeader() -> UIView {
        let label = UILabel()
        label.text = "Eligible for instalments"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(red: 0.18, green: 0.40, blue: 0.95, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView()
        if #available(iOS 13.0, *) {
            icon.image = UIImage(systemName: "megaphone.fill")
        }
        icon.tintColor = UIColor(red: 0.18, green: 0.40, blue: 0.95, alpha: 1.0)
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
        ])
        return row
    }

    // MARK: - Pills

    private func makePillRow() -> UIView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let payInFull = makePillButton(title: "Pay in full", index: 0)
        pillButtons = [payInFull]
        stack.addArrangedSubview(payInFull)

        for (i, plan) in plans.enumerated() {
            let count = plan.numberOfInstallments ?? 0
            let title = "\(count) months"
            let btn = makePillButton(title: title, index: i + 1)
            pillButtons.append(btn)
            stack.addArrangedSubview(btn)
        }

        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scroll.heightAnchor),
        ])
        return scroll
    }

    private func makePillButton(title: String, index: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.layer.cornerRadius = 8
        btn.layer.borderWidth = 1
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        btn.tag = index
        btn.addTarget(self, action: #selector(pillTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func pillTapped(_ sender: UIButton) {
        let oldIndex = selectedIndex
        selectedIndex = sender.tag
        refreshPillAppearance()
        refreshDetailVisibility()
        if oldIndex != selectedIndex { onSizeChange?() }
        emitSelectionChange()
    }

    private func refreshPillAppearance() {
        let blue = UIColor(red: 0.18, green: 0.40, blue: 0.95, alpha: 1.0)
        for (i, btn) in pillButtons.enumerated() {
            let selected = i == selectedIndex
            btn.layer.borderColor = selected ? blue.cgColor : UIColor(white: 0.85, alpha: 1).cgColor
            btn.setTitleColor(selected ? blue : UIColor(white: 0.13, alpha: 1), for: .normal)
            btn.backgroundColor = .white
        }
    }

    // MARK: - Detail Section

    private func makeDetailSection() -> UIView {
        detailContainer.axis = .vertical
        detailContainer.spacing = 4
        detailContainer.translatesAutoresizingMaskIntoConstraints = false

        monthlyAmountLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        monthlyAmountLabel.textColor = UIColor(white: 0.1, alpha: 1)

        monthlyForLabel.font = .systemFont(ofSize: 14, weight: .regular)
        monthlyForLabel.textColor = UIColor(white: 0.4, alpha: 1)
        monthlyForLabel.textAlignment = .right

        let topRow = UIStackView(arrangedSubviews: [monthlyAmountLabel, monthlyForLabel])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .firstBaseline
        topRow.distribution = .equalSpacing

        monthlyRateLabel.font = .systemFont(ofSize: 13, weight: .regular)
        monthlyRateLabel.textColor = UIColor(white: 0.3, alpha: 1)
        monthlyRateLabel.numberOfLines = 0

        processingFeesLabel.font = .systemFont(ofSize: 13, weight: .regular)
        processingFeesLabel.textColor = UIColor(white: 0.3, alpha: 1)
        processingFeesLabel.numberOfLines = 0

        totalLabel.font = .systemFont(ofSize: 13, weight: .regular)
        totalLabel.textColor = UIColor(white: 0.3, alpha: 1)
        totalLabel.textAlignment = .right
        totalLabel.numberOfLines = 0

        let bottomRow = UIStackView(arrangedSubviews: [
            UIStackView.vertical(spacing: 2, [monthlyRateLabel, processingFeesLabel]),
            totalLabel
        ])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .top
        bottomRow.spacing = 12

        detailContainer.addArrangedSubview(topRow)
        detailContainer.addArrangedSubview(bottomRow)
        return detailContainer
    }

    private func refreshDetailVisibility() {
        if selectedIndex == 0 {
            detailContainer.isHidden = true
            termsRow.isHidden = true
            return
        }
        guard selectedIndex - 1 < plans.count else { return }
        let plan = plans[selectedIndex - 1]
        let cost = plan.costInfo
        let currency = cost?.currency
        let monthlyAmount = Amount(currencyCode: currency, value: cost?.lastInstallment?.amount.map { Double($0) } ?? cost?.lastInstallment?.totalAmount).getFormattedAmount2Decimal()
        let total = Amount(currencyCode: currency, value: cost?.totalPlanCost).getFormattedAmount2Decimal()
        let upfront = Amount(currencyCode: currency, value: cost?.totalUpfrontFees).getFormattedAmount2Decimal()
        let monthsCount = plan.numberOfInstallments ?? 0
        let rate = cost?.annualPercentageRate ?? 0

        monthlyAmountLabel.text = "\(monthlyAmount) / Month"
        monthlyForLabel.text = "for \(monthsCount) months"
        monthlyRateLabel.text = String(format: "Monthly rate: %.2f%%", rate)
        processingFeesLabel.text = "+ Processing fees: \(upfront)"
        totalLabel.text = "Total: \(total)"

        detailContainer.isHidden = false
        termsRow.isHidden = false
    }

    // MARK: - Terms Row

    private func makeTermsRow() -> UIView {
        termsCheckbox.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            termsCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
            termsCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        }
        termsCheckbox.tintColor = UIColor(red: 0.18, green: 0.40, blue: 0.95, alpha: 1.0)
        termsCheckbox.addTarget(self, action: #selector(termsToggled), for: .touchUpInside)
        NSLayoutConstraint.activate([
            termsCheckbox.widthAnchor.constraint(equalToConstant: 22),
            termsCheckbox.heightAnchor.constraint(equalToConstant: 22),
        ])

        termsTextLabel.font = .systemFont(ofSize: 13, weight: .regular)
        termsTextLabel.textColor = UIColor(white: 0.3, alpha: 1)
        termsTextLabel.numberOfLines = 0
        let title = NSMutableAttributedString(
            string: "Terms and condition's\n",
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                         .foregroundColor: UIColor.black]
        )
        title.append(NSAttributedString(
            string: "By continuing you agree to the terms and conditions",
            attributes: [.font: UIFont.systemFont(ofSize: 13, weight: .regular),
                         .foregroundColor: UIColor(white: 0.4, alpha: 1)]
        ))
        termsTextLabel.attributedText = title

        termsRow.axis = .horizontal
        termsRow.spacing = 10
        termsRow.alignment = .top
        termsRow.translatesAutoresizingMaskIntoConstraints = false
        termsRow.addArrangedSubview(termsCheckbox)
        termsRow.addArrangedSubview(termsTextLabel)
        termsRow.isHidden = true
        return termsRow
    }

    @objc private func termsToggled() {
        termsAccepted.toggle()
        termsCheckbox.isSelected = termsAccepted
        emitSelectionChange()
    }

    // MARK: - Footer

    private func makeFooter() -> UIView {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let attr = NSMutableAttributedString(
            string: "Instalment enabled by ",
            attributes: [.font: UIFont.systemFont(ofSize: 13, weight: .medium),
                         .foregroundColor: UIColor(red: 0.18, green: 0.40, blue: 0.95, alpha: 1.0)]
        )
        attr.append(NSAttributedString(
            string: "VISA",
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .heavy),
                         .foregroundColor: UIColor(red: 0.10, green: 0.20, blue: 0.55, alpha: 1.0)]
        ))
        label.attributedText = attr
        return label
    }

    // MARK: - Selection Emit

    private func emitSelectionChange() {
        if selectedIndex == 0 {
            onSelectionChanged?(nil, true)
            return
        }
        guard selectedIndex - 1 < plans.count else {
            onSelectionChanged?(nil, true)
            return
        }
        onSelectionChanged?(plans[selectedIndex - 1], termsAccepted)
    }
}

private extension UIStackView {
    static func vertical(spacing: CGFloat, _ views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }
}
