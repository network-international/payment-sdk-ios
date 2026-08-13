//
//  StringExtensionTests.swift
//  NISdkTests
//

import XCTest
@testable import NISdk

final class StringLuhnTests: XCTestCase {

    func testAcceptsKnownGoodTestCards() {
        let valid = [
            "4111111111111111",   // Visa
            "4242424242424242",   // Visa
            "5555555555554444",   // Mastercard
            "378282246310005",    // Amex
            "6011111111111117",   // Discover
            "30569309025904",     // Diners
            "3530111333300000"    // JCB
        ]
        for pan in valid {
            XCTAssertTrue(pan.isValidLuhn(), "\(pan) should pass the Luhn check")
        }
    }

    func testRejectsSingleDigitTypo() {
        XCTAssertFalse("4111111111111112".isValidLuhn())
        XCTAssertFalse("5555555555554443".isValidLuhn())
    }

    func testRejectsNonDigits() {
        XCTAssertFalse("4111 1111 1111 1111".isValidLuhn(), "spaces must not be silently ignored")
        XCTAssertFalse("4111-1111-1111-1111".isValidLuhn())
        XCTAssertFalse("not a card".isValidLuhn())
    }

    func testEmptyStringPassesBecauseSumIsZero() {
        // Documents current behaviour: emptiness is the caller's job to reject, not Luhn's.
        XCTAssertTrue("".isValidLuhn())
    }

    func testDoublingWrapsCorrectlyForEachDigit() {
        // "18" -> doubling the 1 gives 2, plus 8 = 10, divisible by 10.
        XCTAssertTrue("18".isValidLuhn())
        // "91" -> the 9 in an odd position contributes 9, plus 1 = 10.
        XCTAssertTrue("91".isValidLuhn())
        XCTAssertTrue("00".isValidLuhn())
    }
}

final class StringInsertTests: XCTestCase {

    func testGroupsPANIntoFours() {
        XCTAssertEqual("1234567890123456".inserting(separator: " ", every: 4),
                       "1234 5678 9012 3456")
    }

    func testTrailingPartialGroupIsLeftAlone() {
        XCTAssertEqual("123456789".inserting(separator: " ", every: 4), "1234 5678 9")
    }

    func testShorterThanGroupIsUnchanged() {
        XCTAssertEqual("123".inserting(separator: " ", every: 4), "123")
        XCTAssertEqual("".inserting(separator: " ", every: 4), "")
    }

    func testMultiCharacterSeparator() {
        XCTAssertEqual("123456".inserting(separator: "--", every: 2), "12--34--56")
    }

    func testMutatingFormMatchesNonMutatingForm() {
        var value = "378282246310005"
        value.insert(separator: " ", every: 4)
        XCTAssertEqual(value, "378282246310005".inserting(separator: " ", every: 4))
    }
}

final class StringURLEncodeTests: XCTestCase {

    func testSpacesBecomePlusSigns() {
        XCTAssertEqual("John Smith".encodeAsURL(), "John+Smith")
    }

    func testReservedCharactersArePercentEncoded() {
        XCTAssertEqual("a&b=c".encodeAsURL(), "a%26b%3Dc")
        XCTAssertEqual("100%".encodeAsURL(), "100%25")
    }

    func testUnreservedCharactersSurviveUntouched()  {
        XCTAssertEqual("abcXYZ123-._*".encodeAsURL(), "abcXYZ123-._*")
    }

    func testNonASCIIIsUTF8PercentEncoded() {
        XCTAssertEqual("é".encodeAsURL(), "%C3%A9")
    }

    func testReplaceURLsWrapsEachURLAsMarkdown() {
        let input = "See https://example.com/a for details"
        XCTAssertEqual(input.replaceURLs(),
                       "See [https://example.com/a](https://example.com/a) for details")
    }

    func testReplaceURLsHandlesMultipleURLs() {
        let input = "http://a.com and https://b.com"
        XCTAssertEqual(input.replaceURLs(),
                       "[http://a.com](http://a.com) and [https://b.com](https://b.com)")
    }

    func testReplaceURLsLeavesPlainTextAlone() {
        XCTAssertEqual("no links here".replaceURLs(), "no links here")
    }
}

final class StringWhitespaceTests: XCTestCase {

    func testRemoveWhitespaceStripsEverySpace() {
        XCTAssertEqual("4111 1111 1111 1111".removeWhitespace(), "4111111111111111")
        XCTAssertEqual("  a  b  ".removeWhitespace(), "ab")
    }

    func testRemoveWhitespaceOnlyTargetsSpaces() {
        XCTAssertEqual("a\tb".removeWhitespace(), "a\tb", "tabs are out of scope for this helper")
    }

    func testReplaceIsLiteralNotRegex() {
        XCTAssertEqual("a.b.c".replace(string: ".", replacement: "-"), "a-b-c")
    }
}

final class StringEnvTests: XCTestCase {

    func testSandboxAndUATHostsResolveToUAT() {
        XCTAssertEqual("https://api-gateway-uat.ngenius-payments.com".ngenEnv(), .UAT)
        XCTAssertEqual("https://api-gateway.sandbox.ngenius-payments.com".ngenEnv(), .UAT)
        XCTAssertEqual("HTTPS://API-GATEWAY-UAT.NGENIUS-PAYMENTS.COM".ngenEnv(), .UAT,
                       "matching must be case-insensitive")
    }

    func testDevHostResolvesToDev() {
        XCTAssertEqual("https://api-gateway-dev.ngenius-payments.com".ngenEnv(), .DEV)
    }

    func testAnythingElseIsTreatedAsProduction() {
        XCTAssertEqual("https://api-gateway.ngenius-payments.com".ngenEnv(), .PROD)
        XCTAssertEqual("".ngenEnv(), .PROD)
    }

    func testUATWinsWhenAHostLooksLikeBoth() {
        // "-uat" is checked first, so a host carrying both markers is classed as UAT.
        XCTAssertEqual("https://api-uat-dev.example.com".ngenEnv(), .UAT)
    }
}
