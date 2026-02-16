//
//  WhatYouNeedView.swift
//  Simple Integration
//
//  Copyright 2024 Network International. All rights reserved.
//

import SwiftUI

struct WhatYouNeedView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // N-Genius Portal (Required)
                CategorySection(title: "N-Genius Portal (Required)") {
                    SetupItemRow(
                        name: "API Key",
                        description: "Base64-encoded authentication credential",
                        source: "N-Genius Portal \u{2192} Settings \u{2192} API Keys",
                        codeLocation: "Settings \u{2192} Environments \u{2192} Add Environment"
                    )
                    SetupItemRow(
                        name: "Outlet Reference",
                        description: "Unique identifier for your merchant outlet",
                        source: "N-Genius Portal \u{2192} Settings \u{2192} Organizational Hierarchy \u{2192} Outlet",
                        codeLocation: "Settings \u{2192} Environments \u{2192} Add Environment"
                    )
                    SetupItemRow(
                        name: "Realm",
                        description: "Authentication realm for your organization",
                        source: "N-Genius Portal \u{2192} Settings \u{2192} Organizational Hierarchy",
                        codeLocation: "Settings \u{2192} Environments \u{2192} Add Environment"
                    )
                }

                // Apple Pay (Optional)
                CategorySection(title: "Apple Pay (Optional)") {
                    SetupItemRow(
                        name: "Apple Pay Merchant ID",
                        description: "Apple Pay merchant identifier for payment processing",
                        source: "Apple Developer Portal \u{2192} Certificates, Identifiers & Profiles \u{2192} Merchant IDs",
                        codeLocation: "StoreFrontViewController.swift \u{2192} makeApplePayRequest() \u{2192} merchantIdentifier"
                    )
                }

                // Click to Pay (Optional)
                CategorySection(title: "Click to Pay (Optional)") {
                    SetupItemRow(
                        name: "DPA ID",
                        description: "Digital Payment Application identifier",
                        source: "Network International / Click to Pay onboarding",
                        codeLocation: "StoreFrontViewController.swift \u{2192} makeClickToPayConfig()"
                    )
                    SetupItemRow(
                        name: "DPA Client ID",
                        description: "Digital Payment Application client identifier",
                        source: "Network International / Click to Pay onboarding",
                        codeLocation: "StoreFrontViewController.swift \u{2192} makeClickToPayConfig()"
                    )
                }
            }
            .padding()
        }
    }
}

private struct CategorySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Divider()
            content
        }
    }
}

private struct SetupItemRow: View {
    let name: String
    let description: String
    let source: String
    let codeLocation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.bold)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "arrow.down.doc")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Where to get it:")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text(source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Where to set it:")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text(codeLocation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
}
