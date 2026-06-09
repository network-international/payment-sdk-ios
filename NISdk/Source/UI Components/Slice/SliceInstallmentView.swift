import SwiftUI

struct SliceInstallmentView: View {
    let offers: [SliceOffer]
    var onOfferSelected: (SliceOffer?) -> Void

    @State private var selectedIndex: Int = 0

    private let yellowBg = Color(red: 1, green: 0.97, blue: 0.88)
    private let selectedTabBg = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let unselectedTabBg = Color(red: 0.94, green: 0.94, blue: 0.94)
    private let zeroInterestColor = Color(red: 47.0/255.0, green: 191.0/255.0, blue: 113.0/255.0)
    private let zeroFeeColor = Color(red: 47.0/255.0, green: 191.0/255.0, blue: 113.0/255.0)

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
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(installmentAmt)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    Text("Per Month")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
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

    private let banner: SliceBannerUIView
    private let offers: [SliceOffer]
    private let isIslamic: Bool
    private let onOfferSelected: (SliceOffer?) -> Void
    private let pillBleed: UIEdgeInsets
    // Pay in Full (index 0) is the default selection — the user can switch to an offer
    // via the tab row, but never has to start from a no-selection state.
    private var selectedIndex = 0

    private let mainStack = UIStackView()
    private var tabButtons: [UIButton] = []
    private let detailCard = UIView()
    private let selectionErrorLabel = UILabel()

    private let installmentLabel = UILabel()
    private let amountCaptionLabel = UILabel()
    private let zeroInterestBadge = SlicePaddedLabel()
    private let zeroFeesBadge = SlicePaddedLabel()
    private let rateValueLabel = UILabel()
    private let feeValueLabel = UILabel()
    private let totalLabelLabel = UILabel()
    private let totalValueLabel = UILabel()

    init(banner: SliceBannerUIView,
         offers: [SliceOffer],
         isIslamic: Bool = false,
         pillBleed: UIEdgeInsets = .zero,
         onOfferSelected: @escaping (SliceOffer?) -> Void) {
        self.banner = banner
        self.offers = offers
        self.isIslamic = isIslamic
        self.pillBleed = pillBleed
        self.onOfferSelected = onOfferSelected
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = false
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        banner.removeFromSuperview()
        mainStack.addArrangedSubview(banner)
        mainStack.addArrangedSubview(makeTabRow())
        mainStack.addArrangedSubview(makeSelectionErrorLabel())
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

        // Horizontal scroll containing the pill stack.
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.clipsToBounds = false
        scroll.addSubview(stack)
        // Stack pads itself to keep the first pill visually aligned with the section content
        // even though the scroll's frame extends to the screen edges.
        stack.layoutMargins = UIEdgeInsets(top: 0, left: pillBleed.left, bottom: 0, right: pillBleed.right)
        stack.isLayoutMarginsRelativeArrangement = true
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.heightAnchor.constraint(equalTo: scroll.heightAnchor),
        ])

        // Wrap in a hit-test-forwarding container so the scroll can extend past the
        // wrapper's bounds (negative leading/trailing) and still receive touches.
        let wrapper = SliceBleedWrapper()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.clipsToBounds = false
        wrapper.addSubview(scroll)
        wrapper.bleedTarget = scroll
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: wrapper.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: -pillBleed.left),
            scroll.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: pillBleed.right),
        ])
        return wrapper
    }

    private func makeTabButton(title: String, index: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = PgType.pillTabUnselected
        // Capsule pill: fixed height with cornerRadius = height / 2 (matches Android Radius.pill 20dp ≈ tabHeight/2).
        btn.layer.cornerRadius = PgSize.tabHeight / 2
        btn.clipsToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        btn.heightAnchor.constraint(equalToConstant: PgSize.tabHeight).isActive = true
        btn.tag = index
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let wasShowingDetail = !detailCard.isHidden
        selectedIndex = sender.tag
        refreshTabAppearance()
        if selectedIndex > 0 {
            updateDetailContent(offer: offers[selectedIndex - 1])
            onOfferSelected(offers[selectedIndex - 1])
            detailCard.isHidden = false
        } else {
            onOfferSelected(nil)
            detailCard.isHidden = true
        }
        if wasShowingDetail != !detailCard.isHidden { onSizeChange?() }
    }

    private func refreshTabAppearance() {
        for (i, btn) in tabButtons.enumerated() {
            let sel = i == selectedIndex
            btn.backgroundColor = sel ? PgColors.accentPrimary : PgColors.surfacePage
            btn.setTitleColor(sel ? PgColors.textOnTabSelected : PgColors.textSecondary, for: .normal)
            btn.titleLabel?.font = sel ? PgType.pillTabSelected : PgType.pillTabUnselected
            btn.layer.borderColor = sel ? PgColors.accentPrimary.cgColor : PgColors.borderTabUnselected.cgColor
            btn.layer.borderWidth = 1
        }
    }

    // MARK: - Detail Card

    private func makeDetailCard() -> UIView {
        detailCard.translatesAutoresizingMaskIntoConstraints = false
        detailCard.backgroundColor = PgColors.surfaceSliceDetail
        detailCard.layer.cornerRadius = PgRadius.row
        detailCard.isHidden = true

        installmentLabel.font = .systemFont(ofSize: 13, weight: .medium)
        installmentLabel.textColor = PgColors.textPrimary
        installmentLabel.adjustsFontSizeToFitWidth = true
        installmentLabel.minimumScaleFactor = 0.9
        installmentLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        installmentLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        amountCaptionLabel.font = PgType.bodyRowSubtitle
        amountCaptionLabel.textColor = PgColors.textSecondary
        amountCaptionLabel.isHidden = true

        let amountStack = UIStackView(arrangedSubviews: [installmentLabel, amountCaptionLabel])
        amountStack.axis = .vertical
        amountStack.spacing = 2
        amountStack.alignment = .leading

        zeroInterestBadge.configure(text: "Zero interest", color: PgColors.badgeDarkBg)
        zeroFeesBadge.configure(text: "Zero fees", color: PgColors.badgeDarkBg)
        zeroInterestBadge.isHidden = true
        zeroFeesBadge.isHidden = true

        let badgeStack = UIStackView(arrangedSubviews: [zeroInterestBadge, zeroFeesBadge])
        badgeStack.axis = .horizontal
        badgeStack.spacing = 4

        let topRow = UIStackView(arrangedSubviews: [amountStack, badgeStack])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        let divider = UIView()
        divider.backgroundColor = PgColors.dividerSlice
        divider.translatesAutoresizingMaskIntoConstraints = false

        rateValueLabel.font = .systemFont(ofSize: PgType.captionSlicePeriod.pointSize, weight: .semibold)
        rateValueLabel.textColor = PgColors.textPrimary
        rateValueLabel.textAlignment = .right
        feeValueLabel.font = .systemFont(ofSize: PgType.captionSlicePeriod.pointSize, weight: .semibold)
        feeValueLabel.textColor = PgColors.textPrimary
        feeValueLabel.textAlignment = .right

        totalLabelLabel.font = PgType.captionSlicePeriod
        totalLabelLabel.textColor = PgColors.textSecondary
        totalValueLabel.font = .systemFont(ofSize: PgType.captionSlicePeriod.pointSize, weight: .semibold)
        totalValueLabel.textColor = PgColors.textPrimary
        totalValueLabel.textAlignment = .right

        let totalRow = UIStackView(arrangedSubviews: [totalLabelLabel, totalValueLabel])
        totalRow.axis = .horizontal
        totalRow.spacing = 8

        let detailRows = UIStackView(arrangedSubviews: [
            makeDetailRow(labelText: (isIslamic ? "Murabaha:" : "Interest rate:"), valueLabel: rateValueLabel),
            makeDetailRow(labelText: "Processing fees:", valueLabel: feeValueLabel),
            totalRow,
        ])
        detailRows.axis = .vertical
        detailRows.spacing = 8
        detailRows.translatesAutoresizingMaskIntoConstraints = false

        detailCard.addSubview(topRow)
        detailCard.addSubview(divider)
        detailCard.addSubview(detailRows)
        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: detailCard.topAnchor, constant: 12),
            topRow.leadingAnchor.constraint(equalTo: detailCard.leadingAnchor, constant: 12),
            topRow.trailingAnchor.constraint(equalTo: detailCard.trailingAnchor, constant: -8),
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
        installmentLabel.attributedText = AedSymbol.attributed(
            instAmt, font: installmentLabel.font, color: PgColors.textPrimary)
        amountCaptionLabel.text = "Per Month"
        amountCaptionLabel.isHidden = false
        let isZeroInterest = ["0", "0.0", "0.00"].contains(offer.rate)
        let isZeroFee = ["0", "0.0", "0.00"].contains(offer.fee)
        zeroInterestBadge.isHidden = !isZeroInterest
        zeroFeesBadge.isHidden = !isZeroFee
        rateValueLabel.text = "\(offer.rate)%"
        let feeText = offer.feeType == "P"
            ? "\(offer.fee)%"
            : fmtAmt(Int((Double(offer.fee) ?? 0) * 100), offer.installmentAmount.currencyCode)
        feeValueLabel.attributedText = AedSymbol.attributed(
            feeText, font: feeValueLabel.font, color: PgColors.textPrimary)
        totalLabelLabel.text = "Total after \(offer.period) months"
        totalValueLabel.attributedText = AedSymbol.attributed(
            fmtAmt(offer.totalAmount.value, offer.totalAmount.currencyCode),
            font: totalValueLabel.font, color: PgColors.textPrimary)
    }

    private func fmtAmt(_ value: Int, _ currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = true
        f.groupingSeparator = ","
        let n = f.string(from: NSNumber(value: Double(value) / 100.0)) ?? "0.00"
        return "\(currency) \(n)"
    }

    // MARK: - Selection Error

    private func makeSelectionErrorLabel() -> UIView {
        selectionErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionErrorLabel.font = .systemFont(ofSize: 13, weight: .regular)
        selectionErrorLabel.textColor = UIColor(red: 0.83, green: 0.18, blue: 0.18, alpha: 1.0)
        selectionErrorLabel.numberOfLines = 0
        selectionErrorLabel.text = "Select Payment Option Validation".localized
        selectionErrorLabel.isHidden = true
        return selectionErrorLabel
    }

    func showSelectionError() {
        let wasHidden = selectionErrorLabel.isHidden
        selectionErrorLabel.isHidden = false
        if wasHidden { onSizeChange?() }
    }

    func hideSelectionError() {
        let wasVisible = !selectionErrorLabel.isHidden
        selectionErrorLabel.isHidden = true
        if wasVisible { onSizeChange?() }
    }
}

// MARK: - SliceBleedWrapper
//
// Container whose `bleedTarget` (the pill scroll view) extends past its own bounds via
// negative leading/trailing constraints. UIView's default hitTest is bounded by `self.bounds`,
// which would drop touches that land on the bleeding subview. Override forwards them.

final class SliceBleedWrapper: UIView {
    weak var bleedTarget: UIView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let target = bleedTarget {
            let p = convert(point, to: target)
            if target.bounds.contains(p), let hit = target.hitTest(p, with: event) {
                return hit
            }
        }
        return super.hitTest(point, with: event)
    }
}

// MARK: - SlicePaddedLabel

final class SlicePaddedLabel: UILabel {
    func configure(text: String, color: UIColor) {
        self.text = text
        font = .systemFont(ofSize: 10, weight: .medium)
        textColor = .white
        backgroundColor = color
        textAlignment = .center
        clipsToBounds = true
        adjustsFontSizeToFitWidth = true
        minimumScaleFactor = 0.8
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 80, height: 20)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

// MARK: - SliceBannerUIView
//
// Standalone Slice brand banner. Used both above the offer pills (eligible state) and on its
// own when the order's Slice link is present but the entered card returned no matched offers.
final class SliceBannerUIView: UIView {

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = PgColors.surfaceRow
        layer.cornerRadius = PgRadius.row

        let sdkBundle = NISdk.sharedInstance.getBundle()

        let sliceLogo = UIImageView(image: UIImage(named: "sliceLogo", in: sdkBundle, compatibleWith: nil))
        sliceLogo.contentMode = .scaleAspectFit
        sliceLogo.translatesAutoresizingMaskIntoConstraints = false
        sliceLogo.setContentHuggingPriority(.required, for: .horizontal)
        sliceLogo.setContentCompressionResistancePriority(.required, for: .horizontal)

        let topRow = UIStackView(arrangedSubviews: [sliceLogo])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        topRow.addArrangedSubview(spacer)

        let logoAspect: CGFloat = {
            guard let s = sliceLogo.image?.size, s.height > 0 else { return 2.5 }
            return s.width / s.height
        }()
        NSLayoutConstraint.activate([
            sliceLogo.heightAnchor.constraint(equalToConstant: 48),
            sliceLogo.widthAnchor.constraint(equalTo: sliceLogo.heightAnchor, multiplier: logoAspect),
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Zero fees, Zero interest installments."
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = PgColors.textPrimary
        titleLabel.numberOfLines = 2

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Split your purchases into easy installments"
        subtitleLabel.font = PgType.bodyRowSubtitle
        subtitleLabel.textColor = PgColors.textSecondary
        subtitleLabel.numberOfLines = 2

        let mainStack = UIStackView(arrangedSubviews: [topRow, titleLabel, subtitleLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.setCustomSpacing(4, after: titleLabel)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)
        // The bottom is a required `<=` plus a low-priority `=`. This pins content tight to
        // the top while still letting Auto Layout report a natural intrinsic height. If the
        // banner is ever externally forced taller than its content (e.g., a stale container
        // height during a state swap), the equality breaks at low priority and the stack
        // stays at its intrinsic height — leaving any excess as whitespace at the bottom.
        let bottomEqual = mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        bottomEqual.priority = .defaultLow
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14),
            bottomEqual,
        ])
    }

    fileprivate static func makeBankLogo(named name: String, in bundle: Bundle?, width: CGFloat, height: CGFloat = 12) -> UIImageView {
        let iv = UIImageView(image: UIImage(named: name, in: bundle, compatibleWith: nil))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: width),
            iv.heightAnchor.constraint(equalToConstant: height),
        ])
        return iv
    }
}
