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

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text("aani_scan_qr_to_pay".localized)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Spacer().frame(height: 20)

            // QR container with white exclusion zone
            ZStack {
                // White background for exclusion zone
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)

                if let qrImage = generateAaniQRCode(from: qrContent) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding(16) // exclusion zone (2x border width)
                        .accessibilityIdentifier("sdk_aani_image_qr")
                }

                // Aani logo overlay in center
                Image("aaniQrLogo", bundle: NISdk.sharedInstance.getBundle())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .background(Color.white)
                    .padding(2)
            }
            .frame(width: 240, height: 240)

            Spacer().frame(height: 20)

            // Timer with clock icon
            HStack(spacing: 8) {
                Text("\u{23F0}")
                    .font(.system(size: 24))
                Text(timeString)
                    .font(.system(size: 32, weight: .bold))
                    .accessibilityIdentifier("sdk_aani_label_timer")
            }

            Spacer().frame(height: 8)

            Text("aani_note_do_not_close".localized)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Spacer().frame(height: 24)

            // Amount row
            HStack {
                Text(String(format: "aani_paying_amount".localized, ""))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                Text(amountFormatted)
                    .font(.system(size: 16, weight: .semibold))
            }

            Spacer().frame(height: 24)

            // Cancel button
            Button(action: onCancel) {
                Text("Cancel".localized)
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
            }
            .accessibilityIdentifier("sdk_aani_button_cancel")
            .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    /// Generates a QR code with "H" error correction to support the center logo overlay.
    private func generateAaniQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"

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
