//
//  UtilityExtensionTests.swift
//  NISdkTests
//

import XCTest
import UIKit
@testable import NISdk

final class URLQueryParametersTests: XCTestCase {

    func testExtractsEveryQueryItem() {
        let url = URL(string: "https://paypage.example.com/pay?code=ABC123&ref=order-9")!
        XCTAssertEqual(url.queryParameters, ["code": "ABC123", "ref": "order-9"])
    }

    func testReturnsNilWhenThereIsNoQueryString() {
        XCTAssertNil(URL(string: "https://example.com/pay")!.queryParameters)
    }

    func testValueIsPercentDecoded() {
        let url = URL(string: "https://example.com?redirect=https%3A%2F%2Fmerchant.com%2Fdone")!
        XCTAssertEqual(url.queryParameters?["redirect"], "https://merchant.com/done")
    }

    func testLastValueWinsForRepeatedKeys() {
        let url = URL(string: "https://example.com?code=first&code=second")!
        XCTAssertEqual(url.queryParameters?["code"], "second")
    }

    func testAValuelessKeyIsDroppedEntirely() {
        // `result[name] = nil` removes rather than stores, so a bare flag never reaches callers.
        let url = URL(string: "https://example.com?flag&code=ABC")!
        XCTAssertEqual(url.queryParameters, ["code": "ABC"])
    }
}

final class CollectionPairsTests: XCTestCase {

    func testSplitsAnEvenLengthStringIntoPairs() {
        XCTAssertEqual("123456".pairs.map(String.init), ["12", "34", "56"])
    }

    func testTrailingOddElementFormsItsOwnGroup() {
        XCTAssertEqual("12345".pairs.map(String.init), ["12", "34", "5"])
    }

    func testEmptyCollectionYieldsNoPairs() {
        XCTAssertTrue("".pairs.isEmpty)
    }

    func testWorksForArraysToo() {
        let chunks = [1, 2, 3, 4, 5].pairs.map(Array.init)
        XCTAssertEqual(chunks, [[1, 2], [3, 4], [5]])
    }

    func testExpiryDateStyleSplit() {
        // The card preview uses this to break "1225" into month and year.
        XCTAssertEqual("1225".pairs.map(String.init), ["12", "25"])
    }
}

final class UIColorHexTests: XCTestCase {

    func testParsesSixDigitHexWithHash() {
        let color = UIColor(hexString: "#FF0000")
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 1.0, accuracy: 0.001)
        XCTAssertEqual(g, 0.0, accuracy: 0.001)
        XCTAssertEqual(b, 0.0, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }

    func testHashIsOptionalAndCaseIsIgnored() {
        XCTAssertEqual(UIColor(hexString: "00ff00").toHex(), UIColor(hexString: "#00FF00").toHex())
    }

    func testSurroundingWhitespaceIsTrimmed() {
        XCTAssertEqual(UIColor(hexString: "  #0000FF  ").toHex(), "#0000FF")
    }

    func testAlphaIsApplied() {
        var a: CGFloat = 0
        UIColor(hexString: "#FFFFFF", alpha: 0.5).getRed(nil, green: nil, blue: nil, alpha: &a)
        XCTAssertEqual(a, 0.5, accuracy: 0.001)
    }

    func testToHexRoundTrips() {
        for hex in ["#000000", "#FFFFFF", "#123456", "#ABCDEF"] {
            XCTAssertEqual(UIColor(hexString: hex).toHex(), hex)
        }
    }

    func testToHexIgnoresAlpha() {
        XCTAssertEqual(UIColor(hexString: "#112233", alpha: 0.25).toHex(), "#112233")
    }
}

final class TokenUtilsTests: XCTestCase {

    func testExtractsBothCookieTokensFromASetCookieHeader() {
        let header = "access-token=abc123; Path=/; HttpOnly,payment-token=xyz789; Path=/; Secure"
        let tokens = TokenUtils.extractTokens(headerValue: header,
                                              tokenPatterns: ["access-token", "payment-token"])
        XCTAssertEqual(tokens["access-token"], "abc123")
        XCTAssertEqual(tokens["payment-token"], "xyz789")
    }

    func testMissingPatternIsOmittedRatherThanEmpty() {
        let tokens = TokenUtils.extractTokens(headerValue: "access-token=abc; Path=/",
                                              tokenPatterns: ["access-token", "payment-token"])
        XCTAssertEqual(tokens.count, 1)
        XCTAssertNil(tokens["payment-token"])
    }

    func testEmptyHeaderYieldsNoTokens() {
        XCTAssertTrue(TokenUtils.extractTokens(headerValue: "", tokenPatterns: ["access-token"]).isEmpty)
    }

    func testNoPatternsYieldsNoTokens() {
        XCTAssertTrue(TokenUtils.extractTokens(headerValue: "access-token=abc", tokenPatterns: []).isEmpty)
    }

    func testAValueContainingEqualsIsKeptWhole() {
        // Base64 tokens end in "=" padding, so the split must not truncate at the first one.
        let tokens = TokenUtils.extractTokens(headerValue: "access-token=a=b", tokenPatterns: ["access-token"])
        XCTAssertEqual(tokens["access-token"], "a=b")
    }

    func testFirstMatchingSubcomponentWins() {
        let header = "access-token=first; Path=/,access-token=second; Path=/"
        let tokens = TokenUtils.extractTokens(headerValue: header, tokenPatterns: ["access-token"])
        XCTAssertEqual(tokens["access-token"], "first")
    }

    /// The comma is what separates one cookie from the next in a Set-Cookie header, and it has to
    /// be split on *before* the semicolon that separates a cookie's own attributes. Every other
    /// test here happens to put a `;` ahead of the `,`, which makes splitting on either separator
    /// look identical — this one does not, so it fails if the comma split is dropped.
    func testCookiesAreSeparatedByCommaNotJustSemicolon() {
        let header = "payment-token=first,access-token=second"
        let tokens = TokenUtils.extractTokens(headerValue: header,
                                              tokenPatterns: ["payment-token", "access-token"])

        XCTAssertEqual(tokens["payment-token"], "first",
                       "the following cookie must not be swallowed into this token's value")
        XCTAssertEqual(tokens["access-token"], "second")
    }
}
