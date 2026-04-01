//
//  AaniQrLoadingScreen.swift
//  NISdk
//

import SwiftUI

@available(iOS 14.0, *)
struct AaniQrLoadingScreen: View {
    private var goldColor: Color {
        Color(NISdk.sharedInstance.niSdkColors.payButtonGoldColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Golden bordered loading container
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
                    .accessibilityIdentifier("sdk_aani_spinner_loading")

                Text("aani_generating_qr".localized)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 250, height: 250)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(goldColor, lineWidth: 3)
            )

            Spacer().frame(height: 20)

            Text("aani_keep_modal_open".localized)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

@available(iOS 14.0, *)
#Preview {
    AaniQrLoadingScreen()
}
