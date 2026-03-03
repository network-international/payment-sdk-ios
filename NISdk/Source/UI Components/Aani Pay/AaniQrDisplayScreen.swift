//
//  AaniQrDisplayScreen.swift
//  NISdk
//
//  Created on AANI QR support.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

@available(iOS 14.0, *)
struct AaniQrDisplayScreen: View {
    let amountFormatted: String
    let timeString: String
    let qrContent: String
    let onCancel: () -> Void

    private var goldColor: Color {
        Color(NISdk.sharedInstance.niSdkColors.payButtonGoldColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text("aani_scan_qr_to_pay".localized)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer().frame(height: 20)

            // Golden bordered QR container
            VStack(spacing: 16) {
                if let qrImage = generateQRCode(from: qrContent) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                }
            }
            .padding(24)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(goldColor, lineWidth: 3)
            )

            Spacer().frame(height: 20)

            // Timer with clock icon
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text(timeString)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
            }

            Spacer().frame(height: 8)

            Text("aani_note_do_not_close".localized)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Spacer().frame(height: 24)

            // Amount row
            HStack {
                Text("aani_request_to_pay".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(amountFormatted)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 4)

            Spacer().frame(height: 24)

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

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

@available(iOS 14.0, *)
#Preview {
    AaniQrDisplayScreen(
        amountFormatted: "AED 100.00",
        timeString: "04:30",
        qrContent: "https://example.com/pay",
        onCancel: {}
    )
}
