//
//  QPayTests.swift
//  NISdkTests
//
//  The QCB gateway hand-off: decoding its loosely-typed response and building
//  the redirect form that carries the payer to it.
//

import XCTest
@testable import NISdk

final class QPayInitResponseDecodingTests: XCTestCase {

    private func response(_ json: [String: Any]) throws -> QPayInitResponse {
        return try TestFixtures.decode(QPayInitResponse.self, from: json)
    }

    func testDecodesTheGatewaysPascalCaseKeys() throws {
        let decoded = try response([
            "redirectUri": "https://qcb.example.com/pay",
            "Amount": "500",
            "CurrencyCode": "634",
            "PUN": "PUN123",
            "MerchantModuleSessionID": "sess-1",
            "PaymentDescription": "Order 1",
            "NationalID": "nid",
            "MerchantID": "merch-1",
            "BankID": "bank-1",
            "Lang": "en",
            "Action": "0",
            "SecureHash": "hash",
            "TransactionRequestDate": "01012026",
            "ExtraFields_f14": "extra",
            "Quantity": "1"
        ])

        XCTAssertEqual(decoded.redirectUri, "https://qcb.example.com/pay")
        XCTAssertEqual(decoded.amount, "500")
        XCTAssertEqual(decoded.pun, "PUN123")
        XCTAssertEqual(decoded.merchantModuleSessionID, "sess-1")
        XCTAssertEqual(decoded.extraFieldsF14, "extra")
    }

    func testNumericValuesAreCoercedToStrings() throws {
        // QCB returns "Amount": 500 and "Amount": "500" interchangeably.
        let decoded = try response(["Amount": 500, "Quantity": 1, "CurrencyCode": 634])

        XCTAssertEqual(decoded.amount, "500")
        XCTAssertEqual(decoded.quantity, "1")
        XCTAssertEqual(decoded.currencyCode, "634")
    }

    func testAbsentFieldsDecodeToNil() throws {
        let decoded = try response(["redirectUri": "https://qcb.example.com/pay"])

        XCTAssertNil(decoded.amount)
        XCTAssertNil(decoded.secureHash)
        XCTAssertNil(decoded.cancelled)
    }

    func testCancelledFlagIsDecoded() throws {
        XCTAssertEqual(try response(["cancelled": true]).cancelled, true)
        XCTAssertEqual(try response(["cancelled": false]).cancelled, false)
    }

    func testOrderedFormFieldsKeepTheGatewaysExpectedOrder() throws {
        let decoded = try response(["Amount": "500", "PUN": "PUN123"])
        let names = decoded.orderedFormFields.map { $0.name }

        XCTAssertEqual(names, ["Amount", "CurrencyCode", "PUN", "MerchantModuleSessionID",
                               "PaymentDescription", "NationalID", "MerchantID", "BankID",
                               "Lang", "Action", "SecureHash", "TransactionRequestDate",
                               "ExtraFields_f14", "Quantity"])
    }

    func testMissingValuesBecomeEmptyStringsNotDroppedFields() throws {
        let decoded = try response(["Amount": "500"])
        let fields = Dictionary(uniqueKeysWithValues: decoded.orderedFormFields.map { ($0.name, $0.value) })

        XCTAssertEqual(fields["Amount"], "500")
        XCTAssertEqual(fields["SecureHash"], "")
        XCTAssertEqual(decoded.orderedFormFields.count, 14)
    }
}

final class QPayFormBuilderTests: XCTestCase {

    private func response(_ json: [String: Any]) throws -> QPayInitResponse {
        return try TestFixtures.decode(QPayInitResponse.self, from: json)
    }

    func testNormalisesEveryUnicodeDashVariantToASCII() {
        let dashes = ["\u{2010}", "\u{2011}", "\u{2012}", "\u{2013}",
                      "\u{2014}", "\u{2015}", "\u{2212}", "\u{FE58}"]
        for dash in dashes {
            let uri = "https://qcb\(dash)gateway.example.com/pay"
            XCTAssertEqual(QPayFormBuilder.normalizeRedirectUri(uri),
                           "https://qcb-gateway.example.com/pay",
                           "U+\(String(dash.unicodeScalars.first!.value, radix: 16)) was not normalised")
        }
    }

    func testAnAlreadyCleanURIIsUnchanged() {
        let uri = "https://qcb-gateway.example.com/pay?a=1"
        XCTAssertEqual(QPayFormBuilder.normalizeRedirectUri(uri), uri)
    }

    func testAutoSubmitHTMLPostsToTheNormalisedAction() throws {
        let decoded = try response(["redirectUri": "https://qcb\u{2013}gw.example.com/pay", "Amount": "500"])
        let html = try XCTUnwrap(QPayFormBuilder.buildAutoSubmitHTML(response: decoded))

        XCTAssertTrue(html.contains("action=\"https://qcb-gw.example.com/pay\""))
        XCTAssertTrue(html.contains("method=\"post\""))
        XCTAssertTrue(html.contains("document.getElementById('QPayRedirectForm').submit()"))
    }

    func testAutoSubmitHTMLCarriesEveryFieldAsAHiddenInput() throws {
        let decoded = try response(["redirectUri": "https://qcb.example.com/pay",
                                    "Amount": "500", "PUN": "PUN123"])
        let html = try XCTUnwrap(QPayFormBuilder.buildAutoSubmitHTML(response: decoded))

        XCTAssertTrue(html.contains("<input type=\"hidden\" name=\"Amount\" value=\"500\" />"))
        XCTAssertTrue(html.contains("<input type=\"hidden\" name=\"PUN\" value=\"PUN123\" />"))
        XCTAssertEqual(html.components(separatedBy: "<input").count - 1, 14)
    }

    func testValuesAreHTMLEscapedSoTheyCannotBreakOutOfTheAttribute() throws {
        let decoded = try response(["redirectUri": "https://qcb.example.com/pay",
                                    "PaymentDescription": "a\"><script>x</script> & 'b'"])
        let html = try XCTUnwrap(QPayFormBuilder.buildAutoSubmitHTML(response: decoded))

        XCTAssertFalse(html.contains("<script>x</script>"))
        XCTAssertTrue(html.contains("&quot;"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
        XCTAssertTrue(html.contains("&amp;"))
        XCTAssertTrue(html.contains("&#39;"))
    }

    func testNoRedirectURIMeansNoForm() throws {
        XCTAssertNil(QPayFormBuilder.buildAutoSubmitHTML(response: try response(["Amount": "500"])))
        XCTAssertNil(QPayFormBuilder.buildAutoSubmitHTML(response: try response(["redirectUri": ""])))
    }

    func testPOSTRequestTargetsTheNormalisedURL() throws {
        let decoded = try response(["redirectUri": "https://qcb\u{2014}gw.example.com/pay", "Amount": "500"])
        let request = try XCTUnwrap(QPayFormBuilder.buildPOSTRequest(response: decoded))

        XCTAssertEqual(request.url?.absoluteString, "https://qcb-gw.example.com/pay")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Referer"), "https://qcb-gw.example.com/pay")
    }

    func testPOSTBodyIsFormURLEncodedInFieldOrder() throws {
        let decoded = try response(["redirectUri": "https://qcb.example.com/pay",
                                    "Amount": "500", "PaymentDescription": "Order 1 & 2"])
        let request = try XCTUnwrap(QPayFormBuilder.buildPOSTRequest(response: decoded))
        let body = String(data: try XCTUnwrap(request.httpBody), encoding: .utf8)

        XCTAssertTrue(body?.hasPrefix("Amount=500&CurrencyCode=&PUN=") == true)
        XCTAssertTrue(body?.contains("PaymentDescription=Order+1+%26+2") == true,
                      "spaces become '+' and reserved characters are percent-encoded")
        XCTAssertEqual(body?.components(separatedBy: "&").count, 14)
    }

    func testNoRedirectURIMeansNoRequest() throws {
        XCTAssertNil(QPayFormBuilder.buildPOSTRequest(response: try response(["Amount": "500"])))
        XCTAssertNil(QPayFormBuilder.buildPOSTRequest(response: try response(["redirectUri": ""])))
    }

    func testHTMLAndPOSTPathsAgreeOnTheFieldSet() throws {
        let decoded = try response(["redirectUri": "https://qcb.example.com/pay",
                                    "Amount": "500", "PUN": "PUN123", "SecureHash": "hash"])
        let html = try XCTUnwrap(QPayFormBuilder.buildAutoSubmitHTML(response: decoded))
        let body = String(data: try XCTUnwrap(QPayFormBuilder.buildPOSTRequest(response: decoded)?.httpBody),
                          encoding: .utf8) ?? ""

        for field in decoded.orderedFormFields {
            XCTAssertTrue(html.contains("name=\"\(field.name)\""), "\(field.name) missing from the HTML form")
            XCTAssertTrue(body.contains("\(field.name)="), "\(field.name) missing from the POST body")
        }
    }
}
