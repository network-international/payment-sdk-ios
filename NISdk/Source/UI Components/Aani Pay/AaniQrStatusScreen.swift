//
//  AaniQrStatusScreen.swift
//  NISdk
//

import SwiftUI

@available(iOS 14.0, *)
struct AaniQrStatusScreen: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let borderColor: Color
    let buttonText: String
    let onAction: () -> Void
    let onCancel: () -> Void

    private var goldColor: Color {
        Color(NISdk.sharedInstance.niSdkColors.payButtonGoldColor)
    }

    private var goldTextColor: Color {
        Color(NISdk.sharedInstance.niSdkColors.payButtonGoldTextColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Bordered status container
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 3)
            )

            Spacer().frame(height: 32)

            // Action button (gold background)
            Button(action: onAction) {
                Text(buttonText)
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(goldColor)
                    .foregroundColor(goldTextColor)
                    .cornerRadius(12)
            }

            Spacer().frame(height: 12)

            // Cancel button
            Button(action: onCancel) {
                Text("Cancel".localized)
                    .font(.body)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
            }
            .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

@available(iOS 14.0, *)
#Preview {
    AaniQrStatusScreen(
        icon: "exclamationmark.circle.fill",
        iconColor: Color(red: 1.0, green: 0.85, blue: 0.51),
        title: "QR Code Expired",
        subtitle: "QR codes expire after 5 minutes",
        borderColor: Color(red: 1.0, green: 0.85, blue: 0.51),
        buttonText: "Generate New QR Code",
        onAction: {},
        onCancel: {}
    )
}
