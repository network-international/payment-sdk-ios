// swift-tools-version:5.7
import PackageDescription

// The package reuses the existing `NISdk/Source` and `NISdk/Resources` layout so the
// Xcode project, the podspec and the Carthage scheme keep working unchanged.
let package = Package(
    name: "NISdk",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "NISdk",
            targets: ["NISdk"]
        )
    ],
    targets: [
        .target(
            name: "NISdk",
            path: "NISdk",
            exclude: [
                // Umbrella header for the framework build; SwiftPM generates its own module map.
                "Source/NISdk.h",
                // Framework Info.plist; a package target has no Info.plist of its own.
                "Supporting Files"
            ],
            resources: [
                // Card logos and currency symbols (xcassets), the OCRA font, and the
                // en/ar string tables. `.process` compiles the asset catalogs and keeps
                // the .lproj folders so `getBundleFor(language:)` keeps resolving them.
                .process("Resources")
            ]
        )
    ]
)
