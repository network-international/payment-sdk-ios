//
//  NISdkTests.swift
//  NISdkTests
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import XCTest
@testable import NISdk

final class NISdkConfigurationTests: XCTestCase {

    private var sdk: NISdk { NISdk.sharedInstance }
    private var originalLanguage: String!

    override func setUp() {
        super.setUp()
        originalLanguage = sdk.sdkLanguage
    }

    override func tearDown() {
        sdk.setSDKLanguage(language: originalLanguage)
        sdk.isLoggingEnabled = false
        super.tearDown()
    }

    func testSharedInstanceIsASingleton() {
        XCTAssertTrue(NISdk.sharedInstance === NISdk.sharedInstance)
    }

    func testDefaultLanguageIsOneTheSDKShipsStringsFor() {
        XCTAssertTrue(["en", "ar", "fr"].contains(sdk.sdkLanguage),
                      "an unsupported device language must fall back to English")
    }

    func testSettingTheLanguageIsReflectedBack() {
        sdk.setSDKLanguage(language: "ar")
        XCTAssertEqual(sdk.sdkLanguage, "ar")

        sdk.setSDKLanguage(language: "en")
        XCTAssertEqual(sdk.sdkLanguage, "en")
    }

    func testArabicFlipsTheInterfaceToRightToLeft() {
        sdk.setSDKLanguage(language: "ar")
        XCTAssertEqual(UIView.appearance().semanticContentAttribute, .forceRightToLeft)

        sdk.setSDKLanguage(language: "en")
        XCTAssertEqual(UIView.appearance().semanticContentAttribute, .forceLeftToRight)
    }

    func testLoggingIsOffByDefaultAndCanBeToggled() {
        XCTAssertFalse(sdk.isLoggingEnabled, "logging must never be on by default in a payment SDK")

        sdk.isLoggingEnabled = true
        XCTAssertTrue(sdk.isLoggingEnabled)

        sdk.isLoggingEnabled = false
        XCTAssertFalse(sdk.isLoggingEnabled)
    }

    func testColorsCanBeOverridden() {
        let original = sdk.niSdkColors
        defer { sdk.setSDKColors(sdkColors: original) }

        let colors = NISdkColors()
        sdk.setSDKColors(sdkColors: colors)
        XCTAssertTrue(sdk.niSdkColors === colors)
    }

    func testAnUnshippedLanguageFallsBackToTheSDKBundle() {
        // `getBundle()` returns a non-optional, so asserting it is non-nil proves nothing. What is
        // worth pinning is the fallback: an unknown language must resolve to the SDK's own bundle
        // rather than to `Bundle.main`, which would silently pick up the merchant's strings.
        XCTAssertEqual(sdk.getBundleFor(language: "zz").bundlePath, sdk.getBundle().bundlePath)
    }

    func testVersionIsSemver() {
        // "not empty" would pass for any junk; the gateway parses this out of the User-Agent.
        let parts = sdk.version.split(separator: ".")
        XCTAssertEqual(parts.count, 3, "expected MAJOR.MINOR.PATCH, got \(sdk.version)")
        XCTAssertTrue(parts.allSatisfy { Int($0) != nil }, "non-numeric component in \(sdk.version)")
    }
}
