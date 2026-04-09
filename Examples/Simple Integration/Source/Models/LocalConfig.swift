//
//  LocalConfig.swift
//  Simple Integration
//
//  Local credentials file — do NOT commit real values.
//  To set up locally:
//    1. Fill in apiKey, outletReference, and realm below.
//    2. Run: git update-index --skip-worktree "Examples/Simple Integration/Source/Models/LocalConfig.swift"
//

import Foundation

struct LocalConfig {
    /// Pre-populates the production environment into the view model on first launch.
    /// No-op if an environment is already saved.
    static func prePopulate(into viewModel: EnvironmentViewModel) {
        // Fill in your local credentials here (this file is skip-worktree'd from git)
        let apiKey = ""          // e.g. "BASE64_ENCODED_KEY"
        let outletReference = "" // e.g. "abc123"
        let realm = ""           // e.g. "ni"

        guard !apiKey.isEmpty,
              !outletReference.isEmpty,
              !realm.isEmpty,
              Environment.getEnvironments().isEmpty else { return }

        viewModel.addEnvironment(
            name: "Production",
            apiKey: apiKey,
            outletReference: outletReference,
            realm: realm,
            type: .PROD
        )
    }
}
