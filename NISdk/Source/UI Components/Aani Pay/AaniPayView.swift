//
//  AaniPayView.swift
//  NISdk
//
//  Created by Gautam Chibde on 02/08/24.
//

import SwiftUI

@available(iOS 14.0, *)
struct AaniPayView: View {
    @ObservedObject var viewModel: AaniViewModel

    private var layoutDirection: LayoutDirection {
        Locale.characterDirection(forLanguage: NISdk.sharedInstance.sdkLanguage) == .rightToLeft
            ? .rightToLeft : .leftToRight
    }

    var body: some View {
        content
            .accessibilityIdentifier("sdk_aani_container")
            .environment(\.layoutDirection, layoutDirection)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewType {
        case .inputSelection:
            AaniInputScreen(qrEnabled: viewModel.qrEnabled) { type, text in
                viewModel.onSubmit(idType: type, inputText: text)
            }
        case .timer:
            AaniTimerScreen(amountFormatted: viewModel.getAmountFormatted(), timeString: viewModel.timeString)
        case .qrLoading:
            AaniQrLoadingScreen()
        case .qrDisplay:
            AaniQrDisplayScreen(
                amountFormatted: viewModel.getAmountFormatted(),
                timeString: viewModel.timeString,
                qrContent: viewModel.qrContent,
                onCancel: { viewModel.cancelQr() }
            )
        case .qrExpired:
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) {
                    Image("alert-circle", bundle: NISdk.sharedInstance.getBundle())
                        .resizable()
                        .frame(width: 56, height: 56)
                    Text("aani_qr_expired".localized)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(NISdk.sharedInstance.niSdkColors.payButtonGoldColor), lineWidth: 3)
                )
                Spacer().frame(height: 16)
                Text("aani_qr_expired_message".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.horizontal, 24)
        case .qrFailed:
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) {
                    Image("cross-circle", bundle: NISdk.sharedInstance.getBundle())
                        .resizable()
                        .frame(width: 56, height: 56)
                    Text("aani_qr_failed".localized)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.95, green: 0.85, blue: 0.85), lineWidth: 3)
                )
                Spacer().frame(height: 16)
                Text("aani_qr_failed_message".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.horizontal, 24)
        case .paymentTimeout:
            AaniQrStatusScreen(
                icon: "clock.badge.xmark",
                iconColor: .red,
                title: "aani_payment_timeout".localized,
                subtitle: "aani_payment_timeout_message".localized,
                borderColor: Color(red: 0.95, green: 0.85, blue: 0.85),
                buttonText: "aani_try_again".localized,
                onAction: { viewModel.retryPayment() },
                onCancel: { viewModel.cancelQr() }
            )
        }
    }
}
