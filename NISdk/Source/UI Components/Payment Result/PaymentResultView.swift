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

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            if args.isSuccess {
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(successGreen)
            } else {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(failureRed)
            }

            Spacer().frame(height: 24)

            // Title
            if args.isSuccess {
                if let amount = args.amount {
                    Text(String.localizedStringWithFormat("Payment Success Title".localized, amount))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(successGreen)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Payment Success Title No Amount".localized)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(successGreen)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("Payment Failure Title".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(failureRed)
                    .multilineTextAlignment(.center)
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

            Spacer()

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

            Spacer().frame(height: 16)
        }
        .padding(.horizontal, 12)
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
