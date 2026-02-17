//
//  PaymentResultView.swift
//  NISdk
//

import SwiftUI

@available(iOS 13.0, *)
struct PaymentResultView: View {
    let args: PaymentResultArgs
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            if args.isSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(Color(red: 0.18, green: 0.72, blue: 0.32))
            } else {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(Color(red: 0.90, green: 0.22, blue: 0.21))
            }

            Spacer().frame(height: 24)

            // Title
            if args.isSuccess {
                if let amount = args.amount {
                    Text(String.localizedStringWithFormat("Payment Success Title".localized, amount))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Payment Success Title No Amount".localized)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("Payment Failure Title".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 8)

            // Subtitle
            Text(args.isSuccess
                 ? "Payment Success Subtitle".localized
                 : "Payment Failure Subtitle".localized)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 32)

            // Details card
            VStack(spacing: 12) {
                HStack {
                    Text(args.isSuccess
                         ? "Transaction ID Label".localized
                         : "Reference Number Label".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(args.transactionId)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Divider()

                HStack {
                    Text("Date Time Label".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(args.dateTime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)

            Spacer()

            // Done button
            Button(action: { onDone() }) {
                Text("Done".localized)
            }
            .buttonStyle(PaymentButtonStyle(enabled: true))
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.horizontal)
    }
}

@available(iOS 13.0, *)
#Preview {
    PaymentResultView(
        args: PaymentResultArgs(
            isSuccess: true,
            amount: "375.90 AED",
            transactionId: "TXN-123456",
            dateTime: "17 Feb 2026, 10:30 AM"
        ),
        onDone: {}
    )
}
