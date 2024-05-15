// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "NISdk",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "NISdk",
            targets: ["NISdk"]),
    ],
    targets: [
        .target(
            name: "NISdk",
            path: "NISdk",
            exclude: [
                "NISdk/Source/NISdk.h",
                "Supporting Files"
            ],
            resources: [
                .process("Resources")
            ])
    ]
)
