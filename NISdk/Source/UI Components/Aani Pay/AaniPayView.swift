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
            AaniQrStatusScreen(
                icon: "exclamationmark.circle.fill",
                iconColor: Color(NISdk.sharedInstance.niSdkColors.payButtonGoldColor),
                title: "aani_qr_expired".localized,
                subtitle: "aani_qr_expired_message".localized,
                borderColor: Color(NISdk.sharedInstance.niSdkColors.payButtonGoldColor),
                buttonText: "aani_generate_new_qr".localized,
                onAction: { viewModel.retryQr() },
                onCancel: { viewModel.cancelQr() }
            )
        case .qrFailed:
            AaniQrStatusScreen(
                icon: "xmark.circle.fill",
                iconColor: .red,
                title: "aani_qr_failed".localized,
                subtitle: "aani_qr_failed_message".localized,
                borderColor: Color(red: 0.95, green: 0.85, blue: 0.85),
                buttonText: "aani_try_again".localized,
                onAction: { viewModel.retryQr() },
                onCancel: { viewModel.cancelQr() }
            )
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
