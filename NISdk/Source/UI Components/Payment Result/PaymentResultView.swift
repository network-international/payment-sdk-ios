//
//  PaymentResultView.swift
//  NISdk
//

import SwiftUI

@available(iOS 14.0, *)
struct PaymentResultView: View {
    let args: PaymentResultArgs
    let onDone: () -> Void

    private let successGreen = Color(red: 0.184, green: 0.749, blue: 0.443)
    private let failureRed = Color(red: 0.90, green: 0.22, blue: 0.21)
    private let successGreenUI = UIColor(red: 0.184, green: 0.749, blue: 0.443, alpha: 1)

    var body: some View {
        // Full-page scroll — header through Done button all scroll together so nothing gets
        // clipped when the slice receipt section makes the page taller than the viewport.
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                // Merchant header — extends edge-to-edge; reads safe-area inset internally
                // so its background sits behind the status bar while the logo stays clear.
                MerchantResultHeaderView(
                    amount: args.amount,
                    orderItems: args.orderItems
                )

                VStack(spacing: 0) {
                    Spacer().frame(height: 32)

                    // Icon
                    if args.isSuccess {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(successGreen)
                            .accessibilityIdentifier("sdk_result_image_status")
                    } else {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(failureRed)
                            .accessibilityIdentifier("sdk_result_image_status")
                    }

                    Spacer().frame(height: 24)

                    // Title
                    if args.isSuccess {
                        if let amount = args.amount {
                            AedSymbol.swiftUIText(
                                String.localizedStringWithFormat("Payment Success Title".localized, amount),
                                fontSize: 22,
                                tint: successGreenUI
                            )
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(successGreen)
                                .multilineTextAlignment(.center)
                                .accessibilityIdentifier("sdk_result_label_title")
                        } else {
                            Text("Payment Success Title No Amount".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(successGreen)
                                .multilineTextAlignment(.center)
                                .accessibilityIdentifier("sdk_result_label_title")
                        }
                    } else {
                        Text("Payment Failure Title".localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(failureRed)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("sdk_result_label_title")
                    }

                    Spacer().frame(height: 8)

                    // Subtitle
                    Text(args.isSuccess
                         ? "Payment Success Subtitle".localized
                         : "Payment Failure Subtitle".localized)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor(hexString: "#1A1A1A")))
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 32)

                    // Slice success section — only when the user paid via a Slice installment plan.
                    if args.isSuccess, let receipt = args.sliceReceipt {
                        SliceSuccessSection(receipt: receipt)
                        Spacer().frame(height: 24)
                    }

                    // Details - centered text lines
                    HStack(spacing: 0) {
                        Text(args.isSuccess ? "Transaction ID Label".localized : "Reference Number Label".localized)
                            .font(.footnote)
                        Text(": ")
                            .font(.footnote)
                        Text(args.transactionId)
                            .font(.footnote)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer().frame(height: 8)

                    HStack(spacing: 0) {
                        Text("Date Time Label".localized)
                            .font(.footnote)
                        Text(": ")
                            .font(.footnote)
                        Text(args.dateTime)
                            .font(.footnote)
                    }

                    Spacer().frame(height: 24)

                    // Footer
                    PaymentResultFooterView(cardProviders: args.cardProviders)

                    Spacer().frame(height: 16)

                    // Done button
                    Button(action: { onDone() }) {
                        Text("Done".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(args.isSuccess ? successGreen : failureRed)
                            .cornerRadius(8)
                    }
                    .accessibilityIdentifier("sdk_result_button_done")

                    Spacer().frame(height: 16)
                }
                .padding(.horizontal, 12)
            }
        }
    }
}

@available(iOS 14.0, *)
private struct SliceSuccessSection: View {
    let receipt: SliceReceipt

    private let textColor = Color(UIColor(hexString: "#070707"))
    private let lgSize: CGFloat = 16
    // Letter spacing 1% of 16pt cap height ≈ 0.16pt.
    private let labelTracking: CGFloat = 0.16

    var body: some View {
        VStack(spacing: 16) {
            Text("Your purchase has been Sliced successfully!")
                .font(.system(size: lgSize, weight: .medium))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)

            if let logoImage = UIImage(named: "sliceLogo",
                                       in: NISdk.sharedInstance.getBundle(),
                                       compatibleWith: nil) {
                Image(uiImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 170, height: 70)
            }

            VStack(spacing: 12) {
                row(label: "Tenor", value: receipt.tenor)
                row(label: receipt.isIslamic ? "Murabaha" : "Interest rate", value: receipt.interestRate)
                row(label: "Fees", value: receipt.fees)
                row(label: "Instalment amount", value: receipt.installmentAmount)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: lgSize, weight: .regular))
                .tracking(labelTracking)
                .foregroundColor(textColor)
            Spacer()
            AedSymbol.swiftUIText(value, fontSize: lgSize)
                .font(.system(size: lgSize, weight: .medium))
                .foregroundColor(textColor)
        }
    }
}

@available(iOS 14.0, *)
private struct PaymentResultFooterView: View {
    let cardProviders: [CardProvider]

    var body: some View {
        VStack(spacing: 12) {
            Divider()

            // Powered by + NI Logo
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .resizable()
                    .frame(width: 12, height: 12)
                    .foregroundColor(Color(UIColor(hexString: "#8F8F8F")))

                Text("Powered by".localized)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor(hexString: "#8F8F8F")))

                if let logoImage = UIImage(named: "networklogo", in: NISdk.sharedInstance.getBundle(), compatibleWith: nil) {
                    Image(uiImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 20)
                }
            }

            // Terms and Conditions | Privacy Policy
            HStack(spacing: 12) {
                Text("Terms and Conditions".localized)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor(hexString: "#8F8F8F")))
                    .onTapGesture {
                        if let url = URL(string: "https://www.network.ae/en/terms-and-conditions") {
                            UIApplication.shared.open(url)
                        }
                    }

                Text("|")
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor(hexString: "#8F8F8F")))

                Text("Privacy Policy".localized)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor(hexString: "#8F8F8F")))
                    .onTapGesture {
                        if let url = URL(string: "https://www.network.ae/en/privacy-notice") {
                            UIApplication.shared.open(url)
                        }
                    }
            }

            // Card logos
            let logoNames = cardLogoNames()
            if !logoNames.isEmpty {
                HStack(spacing: 8) {
                    ForEach(logoNames, id: \.self) { logoName in
                        if let image = UIImage(named: logoName, in: NISdk.sharedInstance.getBundle(), compatibleWith: nil) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 20)
                        }
                    }
                }
            }
        }
    }

    private func cardLogoNames() -> [String] {
        guard !cardProviders.isEmpty else { return [] }
        var logos: [String] = []
        var seen = Set<String>()
        for provider in cardProviders {
            let name: String?
            switch provider {
            case .visa:                     name = "visalogo"
            case .masterCard:               name = "mastercardlogo"
            case .americanExpress:          name = "amexlogo"
            case .dinersClubInternational:  name = "dinerslogo"
            case .jcb:                      name = "jcblogo"
            case .discover:                 name = "discoverlogo"
            default:                        name = nil
            }
            if let name = name, !seen.contains(name) {
                seen.insert(name)
                logos.append(name)
            }
        }
        return logos
    }
}

@available(iOS 14.0, *)
private struct MerchantResultHeaderView: View {
    let amount: String?
    let orderItems: [OrderItem]

    private let surfaceRow = Color(UIColor(hexString: "#F5F9FC"))
    private let mutedGrey = Color(UIColor(hexString: "#8F8F8F"))
    private let primaryText = Color(UIColor(hexString: "#1A1A1A"))

    /// Top safe-area inset of the key window, read at body-eval time. The merchant header's
    /// background extends behind the status bar (the SwiftUI host is pinned full-screen);
    /// this inset is added to the logo row's top padding so the logo itself sits below the
    /// status bar / dynamic island.
    private var statusBarInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow })
            ?? scenes.flatMap { $0.windows }.first
        return window?.safeAreaInsets.top ?? 44
    }

    var body: some View {
        VStack(spacing: 0) {
            // Merchant logo row
            HStack {
                if let logo = NISdk.sharedInstance.merchantLogo
                    ?? UIImage(named: "networklogo", in: NISdk.sharedInstance.getBundle(), compatibleWith: nil) {
                    Image(uiImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 28)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, statusBarInset + 12)
            .padding(.bottom, 12)

            // Order summary (label + amount)
            if let amount = amount {
                HStack {
                    Text("Order summary".localized)
                        .font(.system(size: 13))
                        .foregroundColor(mutedGrey)
                    Spacer()
                    Text(amount)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(primaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Optional item breakdown
            if !orderItems.isEmpty {
                VStack(spacing: 4) {
                    HStack {
                        Text("Item(s)".localized)
                            .font(.system(size: 12))
                            .foregroundColor(mutedGrey)
                        Spacer()
                        Text("Amount".localized)
                            .font(.system(size: 12))
                            .foregroundColor(mutedGrey)
                    }
                    ForEach(orderItems.indices, id: \.self) { index in
                        let item = orderItems[index]
                        HStack {
                            Text(item.name)
                                .font(.system(size: 13))
                                .foregroundColor(primaryText)
                            Spacer()
                            Text(item.amount)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(primaryText)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .background(surfaceRow)
    }
}

@available(iOS 14.0, *)
#Preview {
    PaymentResultView(
        args: PaymentResultArgs(
            isSuccess: true,
            amount: "375.90 AED",
            transactionId: "TXN-123456",
            dateTime: "17 Feb 2026, 10:30 AM",
            cardProviders: [.visa, .masterCard]
        ),
        onDone: {}
    )
}
