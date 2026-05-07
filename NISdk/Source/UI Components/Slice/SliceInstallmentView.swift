import SwiftUI

struct SliceInstallmentView: View {
    let offers: [SliceOffer]
    var onOfferSelected: (SliceOffer?) -> Void

    @State private var selectedIndex: Int = 0

    private let yellowBg = Color(red: 1, green: 0.97, blue: 0.88)
    private let selectedTabBg = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let unselectedTabBg = Color(red: 0.94, green: 0.94, blue: 0.94)
    private let zeroInterestColor = Color(red: 0.0, green: 0.54, blue: 0.48)
    private let zeroFeeColor = Color(red: 0.36, green: 0.42, blue: 0.75)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Banner
            HStack(alignment: .top, spacing: 8) {
                Text("slice »")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.75, blue: 0.65))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Zero fees. Zero interest.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    Text("Split your purchases into easy installments")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                Spacer()
            }
            .padding(10)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.88, green: 0.88, blue: 0.88), lineWidth: 1))

            // Tab row
            HStack(spacing: 8) {
                sliceTab(label: "Pay in Full", index: 0)
                ForEach(Array(offers.enumerated()), id: \.offset) { idx, offer in
                    sliceTab(label: "\(offer.period) months", index: idx + 1)
                }
                Spacer()
            }

            // Detail card (shown for slice tabs only)
            if selectedIndex > 0 {
                let offer = offers[selectedIndex - 1]
                sliceDetailCard(offer: offer)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func sliceTab(label: String, index: Int) -> some View {
        let isSelected = selectedIndex == index
        Text(label)
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : Color(red: 0.1, green: 0.1, blue: 0.1))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? selectedTabBg : unselectedTabBg)
            .clipShape(Capsule())
            .onTapGesture {
                selectedIndex = index
                onOfferSelected(index == 0 ? nil : offers[index - 1])
            }
    }

    @ViewBuilder
    private func sliceDetailCard(offer: SliceOffer) -> some View {
        let installmentAmt = formatAmount(offer.installmentAmount.value, offer.installmentAmount.currencyCode)
        let totalAmt = formatAmount(offer.totalAmount.value, offer.totalAmount.currencyCode)
        let isZeroInterest = offer.rate == "0" || offer.rate == "0.0" || offer.rate == "0.00"
        let isZeroFee = offer.fee == "0" || offer.fee == "0.0" || offer.fee == "0.00"
        let feeDisplay: String = offer.feeType == "P"
            ? "\(offer.fee)%"
            : formatAmount(Int((Double(offer.fee) ?? 0) * 100), offer.installmentAmount.currencyCode)

        VStack(spacing: 0) {
            HStack {
                Text("\(installmentAmt) / month")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                Spacer()
                HStack(spacing: 6) {
                    if isZeroInterest {
                        badge(label: "Zero interest", color: zeroInterestColor)
                    }
                    if isZeroFee {
                        badge(label: "Zero fees", color: zeroFeeColor)
                    }
                }
            }
            .padding(.bottom, 8)

            Divider().background(Color(red: 0.88, green: 0.79, blue: 0.48))

            VStack(spacing: 4) {
                detailRow(label: "Interest rate", value: "\(offer.rate)%")
                detailRow(label: "Processing fees", value: feeDisplay)
                detailRow(label: "Total after \(offer.period) months", value: totalAmt, bold: true)
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(yellowBg)
        .cornerRadius(8)
    }

    @ViewBuilder
    private func badge(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(4)
    }

    @ViewBuilder
    private func detailRow(label: String, value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.33, green: 0.33, blue: 0.33))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: bold ? .semibold : .regular))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
    }

    private func formatAmount(_ minorUnits: Int, _ currencyCode: String) -> String {
        let amount = Double(minorUnits) / 100.0
        return String(format: "\(currencyCode) %.2f", amount)
    }
}

// MARK: - UIKit implementation (used by UnifiedPaymentPageViewController)

import UIKit

final class SliceInstallmentUIView: UIView {

    var onSizeChange: (() -> Void)?

    private let offers: [SliceOffer]
    private let onOfferSelected: (SliceOffer?) -> Void
    private var selectedIndex = 0

    private let mainStack = UIStackView()
    private var tabButtons: [UIButton] = []
    private let detailCard = UIView()

    private let installmentLabel = UILabel()
    private let zeroInterestBadge = SlicePaddedLabel()
    private let zeroFeesBadge = SlicePaddedLabel()
    private let rateValueLabel = UILabel()
    private let feeValueLabel = UILabel()

    init(offers: [SliceOffer], onOfferSelected: @escaping (SliceOffer?) -> Void) {
        self.offers = offers
        self.onOfferSelected = onOfferSelected
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(makeBanner())
        mainStack.addArrangedSubview(makeTabRow())
        mainStack.addArrangedSubview(makeDetailCard())
        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        refreshTabAppearance()
    }

    // MARK: - Banner

    private func makeBanner() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.borderColor = PgColors.borderInput.cgColor
        container.layer.borderWidth = 1
        container.layer.cornerRadius = PgRadius.row

        let sliceLabel = UILabel()
        sliceLabel.text = "slice »"
        sliceLabel.font = .systemFont(ofSize: 14, weight: .bold)
        sliceLabel.textColor = UIColor(red: 0.0, green: 0.75, blue: 0.65, alpha: 1)
        sliceLabel.setContentHuggingPriority(.required, for: .horizontal)
        sliceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        sliceLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Zero fees. Zero interest."
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Split your purchases into easy installments"
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(sliceLabel)
        container.addSubview(textStack)
        NSLayoutConstraint.activate([
            sliceLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            sliceLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            textStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            textStack.leadingAnchor.constraint(equalTo: sliceLabel.trailingAnchor, constant: 8),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
        ])
        return container
    }

    // MARK: - Tab Row

    private func makeTabRow() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        let fullBtn = makeTabButton(title: "Pay in Full", index: 0)
        tabButtons = [fullBtn]
        stack.addArrangedSubview(fullBtn)
        for (i, offer) in offers.enumerated() {
            let btn = makeTabButton(title: "\(offer.period) months", index: i + 1)
            tabButtons.append(btn)
            stack.addArrangedSubview(btn)
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(spacer)
        return stack
    }

    private func makeTabButton(title: String, index: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = PgType.pillTabUnselected
        btn.layer.cornerRadius = PgRadius.pill
        btn.clipsToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        btn.tag = index
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let wasShowingDetail = selectedIndex > 0
        selectedIndex = sender.tag
        refreshTabAppearance()
        let isShowingDetail = selectedIndex > 0
        if isShowingDetail {
            updateDetailContent(offer: offers[selectedIndex - 1])
            onOfferSelected(offers[selectedIndex - 1])
        } else {
            onOfferSelected(nil)
        }
        detailCard.isHidden = !isShowingDetail
        if wasShowingDetail != isShowingDetail { onSizeChange?() }
    }

    private func refreshTabAppearance() {
        for (i, btn) in tabButtons.enumerated() {
            let sel = i == selectedIndex
            btn.backgroundColor = sel ? PgColors.badgeDarkBg : PgColors.surfacePage
            btn.setTitleColor(sel ? PgColors.textOnTabSelected : PgColors.textPrimary, for: .normal)
            btn.titleLabel?.font = sel ? PgType.pillTabSelected : PgType.pillTabUnselected
            btn.layer.borderColor = sel ? UIColor.clear.cgColor : PgColors.borderTabUnselected.cgColor
            btn.layer.borderWidth = sel ? 0 : 1
        }
    }

    // MARK: - Detail Card

    private func makeDetailCard() -> UIView {
        detailCard.translatesAutoresizingMaskIntoConstraints = false
        detailCard.backgroundColor = PgColors.surfaceSliceDetail
        detailCard.layer.cornerRadius = PgRadius.row
        detailCard.isHidden = true

        installmentLabel.font = PgType.amountRow
        installmentLabel.textColor = PgColors.textPrimary
        installmentLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        zeroInterestBadge.configure(text: "Zero interest",
                                    color: UIColor(red: 0.0, green: 0.54, blue: 0.48, alpha: 1))
        zeroFeesBadge.configure(text: "Zero fees",
                                color: UIColor(red: 0.36, green: 0.42, blue: 0.75, alpha: 1))
        zeroInterestBadge.isHidden = true
        zeroFeesBadge.isHidden = true

        let badgeStack = UIStackView(arrangedSubviews: [zeroInterestBadge, zeroFeesBadge])
        badgeStack.axis = .horizontal
        badgeStack.spacing = 6

        let topRow = UIStackView(arrangedSubviews: [installmentLabel, badgeStack])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        let divider = UIView()
        divider.backgroundColor = PgColors.dividerSlice
        divider.translatesAutoresizingMaskIntoConstraints = false

        rateValueLabel.font = PgType.captionSlicePeriod
        rateValueLabel.textColor = PgColors.textPrimary
        rateValueLabel.textAlignment = .right
        feeValueLabel.font = PgType.captionSlicePeriod
        feeValueLabel.textColor = PgColors.textPrimary
        feeValueLabel.textAlignment = .right

        let detailRows = UIStackView(arrangedSubviews: [
            makeDetailRow(labelText: "Interest rate", valueLabel: rateValueLabel),
            makeDetailRow(labelText: "Processing fees", valueLabel: feeValueLabel),
        ])
        detailRows.axis = .vertical
        detailRows.spacing = 4
        detailRows.translatesAutoresizingMaskIntoConstraints = false

        detailCard.addSubview(topRow)
        detailCard.addSubview(divider)
        detailCard.addSubview(detailRows)
        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: detailCard.topAnchor, constant: 12),
            topRow.leadingAnchor.constraint(equalTo: detailCard.leadingAnchor, constant: 12),
            topRow.trailingAnchor.constraint(equalTo: detailCard.trailingAnchor, constant: -12),
            divider.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 8),
            divider.leadingAnchor.constraint(equalTo: detailCard.leadingAnchor, constant: 12),
            divider.trailingAnchor.constraint(equalTo: detailCard.trailingAnchor, constant: -12),
            divider.heightAnchor.constraint(equalToConstant: 1),
            detailRows.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 8),
            detailRows.leadingAnchor.constraint(equalTo: detailCard.leadingAnchor, constant: 12),
            detailRows.trailingAnchor.constraint(equalTo: detailCard.trailingAnchor, constant: -12),
            detailRows.bottomAnchor.constraint(equalTo: detailCard.bottomAnchor, constant: -12),
        ])
        return detailCard
    }

    private func makeDetailRow(labelText: String, valueLabel: UILabel) -> UIView {
        let label = UILabel()
        label.text = labelText
        label.font = PgType.captionSlicePeriod
        label.textColor = PgColors.textSecondary
        let row = UIStackView(arrangedSubviews: [label, valueLabel])
        row.axis = .horizontal
        row.spacing = 8
        return row
    }

    private func updateDetailContent(offer: SliceOffer) {
        let instAmt = fmtAmt(offer.installmentAmount.value, offer.installmentAmount.currencyCode)
        installmentLabel.text = "\(instAmt) / month"
        let isZeroInterest = ["0", "0.0", "0.00"].contains(offer.rate)
        let isZeroFee = ["0", "0.0", "0.00"].contains(offer.fee)
        zeroInterestBadge.isHidden = !isZeroInterest
        zeroFeesBadge.isHidden = !isZeroFee
        rateValueLabel.text = "\(offer.rate)%"
        feeValueLabel.text = offer.feeType == "P"
            ? "\(offer.fee)%"
            : fmtAmt(Int((Double(offer.fee) ?? 0) * 100), offer.installmentAmount.currencyCode)
    }

    private func fmtAmt(_ value: Int, _ currency: String) -> String {
        String(format: "\(currency) %.2f", Double(value) / 100.0)
    }
}

// MARK: - SlicePaddedLabel

final class SlicePaddedLabel: UILabel {
    private let insets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)

    func configure(text: String, color: UIColor) {
        self.text = text
        font = .systemFont(ofSize: 10, weight: .medium)
        textColor = .white
        backgroundColor = color
        layer.cornerRadius = 4
        clipsToBounds = true
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}
