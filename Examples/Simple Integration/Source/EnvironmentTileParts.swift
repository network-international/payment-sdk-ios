//
//  EnvironmentTileParts.swift
//  Simple Integration
//
//  Copyright © 2026 Network International. All rights reserved.
//

import NISdk
import SwiftUI

/// Wraps its subviews onto as many rows as they need.
///
/// SwiftUI has no built-in flow container before iOS 16's `Layout`, and an HStack
/// would push the method pills off the edge rather than wrapping them. Implemented
/// with `Layout` so the rows size themselves to the card's real width.
@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// A card scheme the tile can draw: the gateway's name and the SDK's logo.
struct CardBrand {
    let name: String
    let asset: String
    let label: String
}

/// Every scheme the SDK ships a logo for, in the payment page's own order. All are
/// always drawn so two outlets can be compared at a glance — a missing logo and a
/// scheme this build cannot render look identical, whereas a marked logo says which.
let cardBrands: [CardBrand] = [
    CardBrand(name: "MASTERCARD", asset: "mastercardlogo", label: "Mastercard"),
    CardBrand(name: "VISA", asset: "visalogo", label: "Visa"),
    CardBrand(name: "AMERICAN_EXPRESS", asset: "amexlogo", label: "Amex"),
    CardBrand(name: "DINERS_CLUB_INTERNATIONAL", asset: "dinerslogo", label: "Diners"),
    CardBrand(name: "DISCOVER", asset: "discoverlogo", label: "Discover"),
    CardBrand(name: "JCB", asset: "jcblogo", label: "JCB"),
]

/// Which schemes this outlet accepts. Matched loosely because the gateway's names vary
/// ("AMERICAN_EXPRESS" / "AMEX"), the same way the SDK's own brand strip matches them.
func enabledCardBrands(_ methods: [String]) -> Set<String> {
    let up = methods.map { $0.uppercased() }
    func has(_ needles: String...) -> Bool {
        up.contains { m in needles.contains { m.contains($0) } }
    }
    var found: Set<String> = []
    if has("MASTER") { found.insert("MASTERCARD") }
    // "VISA_CLICK_TO_PAY" is a wallet, not the card scheme.
    if up.contains("VISA") { found.insert("VISA") }
    if has("AMERICAN", "AMEX") { found.insert("AMERICAN_EXPRESS") }
    if has("DINERS") { found.insert("DINERS_CLUB_INTERNATIONAL") }
    if has("DISCOVER") { found.insert("DISCOVER") }
    if has("JCB") { found.insert("JCB") }
    return found
}

/// The named payment methods an outlet offers, as the demo talks about them.
///
/// The gateway reports a hosted wallet and the merchant's own in-app integration as
/// separate names (APPLE_PAY / DIRECT_APPLE_PAY); both mean "this outlet does Apple
/// Pay", so they collapse to one entry. Card schemes are excluded — they are shown as
/// logos instead, which is how the payment page itself presents them.
func namedPaymentMethods(_ raw: [String]) -> [String] {
    let labels: [String: String] = [
        "APPLE_PAY": "Apple Pay",
        "GOOGLE_PAY": "Google Pay",
        "SAMSUNG_PAY": "Samsung Pay",
        "VISA_CLICK_TO_PAY": "Click to Pay",
        "AANI": "Aani",
        "QPAY": "QPay",
        "SLICE": "Slice",
        "TAMARA": "Tamara",
        "TABBY": "Tabby",
        "BENEFIT": "Benefit",
        "NAPS": "NAPS",
        "VISA_INSTALMENTS": "Visa instalments",
    ]
    // Fixed order, so two outlets with the same methods always read the same.
    let order = ["Apple Pay", "Google Pay", "Samsung Pay", "Click to Pay", "Aani", "QPay",
                 "Visa instalments", "Slice", "Tamara", "Tabby", "Benefit", "NAPS"]
    var found: Set<String> = []
    for name in raw {
        let key = name.hasPrefix("DIRECT_") ? String(name.dropFirst("DIRECT_".count)) : name
        if let label = labels[key.uppercased()] { found.insert(label) }
    }
    // Anything this build does not know about still shows rather than vanishing.
    return order.filter { found.contains($0) } + found.filter { !order.contains($0) }.sorted()
}

/// A scheme logo with its status on the bottom edge: accepted or not.
struct CardBrandBadge: View {
    let brand: CardBrand
    let enabled: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                logo
                    // Dimmed rather than hidden: the mark still has to be identifiable.
                    .opacity(enabled ? 1 : 0.35)
                    .frame(width: 40, height: 20)
                Spacer(minLength: 0)
            }
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(enabled ? .green : .red)
                .background(Circle().fill(Color.white).frame(width: 10, height: 10))
        }
        .frame(width: 44, height: 30)
        .accessibilityLabel("\(brand.label) \(enabled ? "accepted" : "not accepted")")
    }

    @ViewBuilder
    private var logo: some View {
        // The scheme logos live in the SDK's bundle, not the app's.
        if let image = UIImage(named: brand.asset, in: Bundle(for: NISdk.self), compatibleWith: nil) {
            Image(uiImage: image).resizable().scaledToFit()
        } else {
            Text(brand.label).font(.system(size: 8)).foregroundColor(.secondary)
        }
    }
}

/// One environment in the Configuration list.
///
/// Its own view for two reasons: the row grew past what the SwiftUI type-checker will
/// infer in reasonable time when it lived inline, and the layout is a Column rather
/// than a Row so the method pills and card logos span the card instead of sharing a
/// gutter with the trailing actions.
struct EnvironmentRow: View {
    let environment: Environment
    let isSelected: Bool
    /// The QA override is on, so this outlet's own region/currency are not what orders use.
    var isOverridden: Bool = false
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let niBlue = Color(red: 0, green: 105 / 255, blue: 177 / 255)

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            header
            Text(environment.realm)
                .font(.caption)
                .foregroundColor(.secondary)
            // Struck through while the QA override is on, so nobody reads these as the
            // values orders will use.
            Text("\(environment.region.rawValue) · \(environment.currency)\(isOverridden ? "  (overridden)" : "")")
                .font(.caption)
                .strikethrough(isOverridden)
                .foregroundColor(.secondary)
            methodPills
            cardBrandStrip
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? niBlue : Color.gray, lineWidth: isSelected ? 2 : 1)
        )
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? niBlue.opacity(0.05) : Color.clear)
        )
        .padding(2)
        .contentShape(Rectangle())
        .onTapGesture { if !isSelected { onSelect() } }
        .accessibilityIdentifier("environment_item_\(environment.id)")
    }

    private var header: some View {
        HStack {
            Text(environment.nickname.isEmpty ? environment.realm : environment.nickname)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(environment.type.rawValue)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(niBlue.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(niBlue, lineWidth: 1))
                .cornerRadius(12)

            Button(action: onEdit) {
                Image(systemName: "pencil").foregroundColor(niBlue)
            }
            .padding(4)
            .accessibilityIdentifier("environment_button_edit_\(environment.id)")

            Button(action: onDelete) {
                Image(systemName: "trash.fill")
            }
            .foregroundColor(.white)
            .padding(4)
            .background(Color.red)
            .cornerRadius(6)
            .accessibilityIdentifier("environment_button_delete_\(environment.id)")
        }
    }

    @ViewBuilder
    private var methodPills: some View {
        let named = namedPaymentMethods(environment.paymentMethods)
        if !named.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(named, id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(niBlue.opacity(0.10))
                        .cornerRadius(6)
                }
            }
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var cardBrandStrip: some View {
        if !environment.paymentMethods.isEmpty {
            let enabled = enabledCardBrands(environment.paymentMethods)
            FlowLayout(spacing: 12) {
                ForEach(cardBrands, id: \.name) { brand in
                    CardBrandBadge(brand: brand, enabled: enabled.contains(brand.name))
                }
            }
            .padding(.top, 8)
        }
    }
}
