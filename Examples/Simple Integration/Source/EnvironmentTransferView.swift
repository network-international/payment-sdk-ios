//
//  EnvironmentTransferView.swift
//  Simple Integration
//
//  Copyright © 2026 Network International. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// Bytes per QR. Byte-mode capacity at error level M is 2331; the headroom keeps the
/// encoder from failing on a long key and matches the outlet-cred-puller's limit, so a
/// batch splits the same way whichever end generates it.
private let qrChunkBytes = 2000

/// Moving environments between devices and the outlet-cred-puller.
///
/// Four routes, all speaking the same pipe-delimited line format: copy to the clipboard,
/// paste from it, show a QR for another device to scan, and scan one. A set of outlets is
/// tedious to retype and easy to mistype — an API key is 200-odd characters of base64 —
/// so every route moves the whole list at once.
struct EnvironmentTransferView: View {
    @ObservedObject var viewModel: EnvironmentViewModel
    let onDone: () -> Void

    @State private var pasted: String = ""
    @State private var qrChunks: [[String]]?
    @State private var isShowingScanner = false
    @State private var message: String?

    private var environments: [Environment] { viewModel.environments }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Transfer Environments").font(.headline)
                Spacer()
                Button("Done", action: onDone)
                    .accessibilityIdentifier("transfer_button_done")
            }
            .padding()

            Form {
                Section {
                    Button("Copy all") { copyAll() }
                        .accessibilityIdentifier("transfer_button_copy")
                    Button("Show QR") { showQr() }
                        .accessibilityIdentifier("transfer_button_showQr")
                } header: {
                    Text("Share")
                } footer: {
                    Text("Sends all \(environments.count) saved environment(s). The payload contains API keys — treat a copied blob or a displayed code as a credential.")
                }

                Section {
                    Button("Scan QR") { isShowingScanner = true }
                        .accessibilityIdentifier("transfer_button_scan")
                    TextEditor(text: $pasted)
                        .frame(minHeight: 90)
                        .accessibilityIdentifier("transfer_field_paste")
                    Button("Paste from clipboard") {
                        pasted = UIPasteboard.general.string ?? pasted
                    }
                    Button("Import") { importText(pasted) }
                        .accessibilityIdentifier("transfer_button_import")
                } header: {
                    Text("Receive")
                } footer: {
                    Text("One environment per line. An outlet already saved is updated in place rather than duplicated.")
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingScanner) {
            QRScannerView(
                onCodesScanned: { codes in
                    isShowingScanner = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        importText(codes.joined(separator: "\n"))
                    }
                },
                onCancel: { isShowingScanner = false }
            )
        }
        .sheet(isPresented: Binding(
            get: { qrChunks != nil },
            set: { if !$0 { qrChunks = nil } }
        )) {
            if let chunks = qrChunks {
                QrPagesView(chunks: chunks, total: environments.count) { qrChunks = nil }
            }
        }
        .alert("Environments", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK") { message = nil }
        } message: {
            Text(message ?? "")
        }
        .environment(\.layoutDirection, .leftToRight)
        .environment(\.locale, Locale(identifier: "en"))
    }

    private func copyAll() {
        guard !environments.isEmpty else {
            message = "No environments to copy."
            return
        }
        UIPasteboard.general.string = ScannedEnvironment.encodeAll(environments)
        message = "\(environments.count) environment(s) copied."
    }

    private func showQr() {
        guard !environments.isEmpty else {
            message = "No environments to share."
            return
        }
        qrChunks = ScannedEnvironment.chunkLines(environments.map(ScannedEnvironment.encode),
                                                 limitBytes: qrChunkBytes)
    }

    private func importText(_ text: String) {
        let batch = ScannedEnvironment.parseAll(text)
        guard !batch.environments.isEmpty else {
            message = "No line matched the expected format."
            return
        }
        let result = viewModel.importEnvironments(batch.environments)
        pasted = ""
        let skipped = batch.rejected > 0 ? ", \(batch.rejected) line(s) skipped" : ""
        message = "\(result.added) added, \(result.replaced) updated\(skipped)."
    }
}

/// The generated codes, one page at a time.
///
/// A batch larger than one QR is split across several rather than shrunk to unscannable
/// density; the receiving scanner accumulates codes, so they can be scanned in any order.
private struct QrPagesView: View {
    let chunks: [[String]]
    let total: Int
    let onDone: () -> Void

    @State private var page = 0

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(total) environment(s)").font(.headline)
                Spacer()
                Button("Done", action: onDone)
            }
            .padding()

            if let image = qrImage(for: chunks[page].joined(separator: "\n")) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                    // A light quiet zone, whatever the surrounding appearance.
                    .padding(12)
                    .background(Color.white)
                    .accessibilityIdentifier("transfer_image_qr")
            } else {
                Text("Could not generate a code for this batch.")
            }

            Text(chunks.count > 1
                 ? "Code \(page + 1) of \(chunks.count) — \(chunks[page].count) outlet(s). Scan them all."
                 : "\(chunks[page].count) outlet(s)")
                .font(.caption)
                .foregroundColor(.secondary)

            if chunks.count > 1 {
                HStack(spacing: 24) {
                    Button("Previous") { page -= 1 }.disabled(page == 0)
                    Button("Next") { page += 1 }.disabled(page == chunks.count - 1)
                }
            }
            Spacer()
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    /// Renders `text` as a QR, or nil if it will not fit even one code.
    private func qrImage(for text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        // CIQRCodeGenerator emits one pixel per module; scale up before rasterising
        // or the code is a blurry thumbnail.
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
