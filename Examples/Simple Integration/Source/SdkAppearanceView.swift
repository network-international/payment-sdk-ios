//
//  SdkAppearanceView.swift
//  Simple Integration
//
//  Copyright © 2026 Network International. All rights reserved.
//

import SwiftUI

/// SDK Appearance — the SDK's runtime look-and-feel, on its own page.
///
/// Separate from the configuration screen because these settings describe how the
/// SDK draws, not which outlet is charged, and eleven colour rows crowded a screen
/// that is mostly about environments. The Android and Flutter demos show the same
/// list under the same name.
struct SdkAppearanceView: View {
    @ObservedObject var viewModel: EnvironmentViewModel
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SDK Appearance")
                    .font(.headline)
                Spacer()
                Button("Done", action: onDone)
                    .accessibilityIdentifier("sdkappearance_button_done")
            }
            .padding()

            Form {
            Section {

                    SDKColorRow(label: "Button", hex: $viewModel.sdkColorPayButton, onSave: viewModel.saveSDKColorPayButton)
                    SDKColorRow(label: "Button Text", hex: $viewModel.sdkColorPayButtonText, onSave: viewModel.saveSDKColorPayButtonText)
                    SDKColorRow(label: "Button Disabled", hex: $viewModel.sdkColorPayButtonDisabled, onSave: viewModel.saveSDKColorPayButtonDisabled)
                    SDKColorRow(label: "Button Disabled Text", hex: $viewModel.sdkColorPayButtonDisabledText, onSave: viewModel.saveSDKColorPayButtonDisabledText)
                    SDKColorRow(label: "Input Field BG", hex: $viewModel.sdkColorInputFieldBg, onSave: viewModel.saveSDKColorInputFieldBg)
                    SDKColorRow(label: "Auth View BG", hex: $viewModel.sdkColorAuthViewBg, onSave: viewModel.saveSDKColorAuthViewBg)
                    SDKColorRow(label: "Auth Indicator", hex: $viewModel.sdkColorAuthViewIndicator, onSave: viewModel.saveSDKColorAuthViewIndicator)
                    SDKColorRow(label: "Auth Label", hex: $viewModel.sdkColorAuthViewLabel, onSave: viewModel.saveSDKColorAuthViewLabel)
                    SDKColorRow(label: "3DS View BG", hex: $viewModel.sdkColorThreeDSViewBg, onSave: viewModel.saveSDKColorThreeDSViewBg)
                    SDKColorRow(label: "3DS Label", hex: $viewModel.sdkColorThreeDSViewLabel, onSave: viewModel.saveSDKColorThreeDSViewLabel)
                    SDKColorRow(label: "3DS Indicator", hex: $viewModel.sdkColorThreeDSViewIndicator, onSave: viewModel.saveSDKColorThreeDSViewIndicator)
            } header: {
                Text("SDK colours")
            } footer: {
                Text("These apply to the SDK's own screens — the payment page, the authorisation view and the 3DS view.")
            }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .environment(\.locale, Locale(identifier: "en"))
    }
}
