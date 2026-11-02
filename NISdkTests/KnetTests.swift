//
//  KnetTests.swift
//  NISdkTests
//
//  KNET (Kuwait debit): when the payment page offers it, which link a payment starts from, and
//  which outcomes hand the payer back to the payment page for another try on the same order.
//

import XCTest
@testable import NISdk

final class KnetEligibilityTests: XCTestCase {

    private static let knetHref =
        "https://api-gateway.sandbox.ngenius-payments.com/transactions/outlets/o1/orders/abc123/payments/pay123/knet"

    private func linksWithKnet() -> [String: Any] {
        var links = TestFixtures.defaultPaymentLinks()
        links["payment:knet"] = ["href": Self.knetHref]
        return links
    }

    /// Shape of a KWD purchase on the UAT `keynet` outlet: KNET listed as a card scheme and the
    /// payment carrying a `payment:knet` link.
    func testKnetIsOfferedWhenThePaymentCarriesAKnetLink() throws {
        let order = try TestFixtures.order(currencyCode: "KWD",
                                           cardSchemes: ["KNET", "VISA", "MASTERCARD"],
                                           paymentLinks: linksWithKnet())

        XCTAssertTrue(order.isKnetSupported)
        XCTAssertEqual(order.embeddedData?.payment?.first?.paymentLinks?.knetLink, Self.knetHref)
    }

    /// Before the backend added the link, KNET appeared only in `paymentMethods.card`. Without a
    /// link there is nothing to start a payment from, so the row stays hidden.
    func testKnetIsHiddenWhenOnlyTheCardSchemeIsListed() throws {
        let order = try TestFixtures.order(currencyCode: "KWD", cardSchemes: ["KNET", "VISA"])

        XCTAssertFalse(order.isKnetSupported)
    }

    func testKnetIsHiddenWhenTheLinkIsEmpty() throws {
        var links = TestFixtures.defaultPaymentLinks()
        links["payment:knet"] = ["href": ""]
        let order = try TestFixtures.order(currencyCode: "KWD", cardSchemes: ["KNET"], paymentLinks: links)

        XCTAssertFalse(order.isKnetSupported)
    }

    /// The order self-link is what each attempt re-reads and what the result is polled from.
    func testKnetIsHiddenWhenTheOrderSelfLinkIsMissing() throws {
        let order = try TestFixtures.order(
            currencyCode: "KWD", cardSchemes: ["KNET"], paymentLinks: linksWithKnet(),
            overrides: ["_links": [
                "payment": ["href": "https://paypage.sandbox.ngenius-payments.com/?code=AUTHCODE123"]
            ]])

        XCTAssertFalse(order.isKnetSupported)
    }

    func testInitArgsUseTheGatewayLinkAsIs() throws {
        let order = try TestFixtures.order(currencyCode: "KWD", cardSchemes: ["KNET"],
                                           paymentLinks: linksWithKnet())
        let args = try order.toKnetInitArgs()

        XCTAssertEqual(args.knetLink, Self.knetHref)
        XCTAssertEqual(args.orderLink, "https://api.sandbox.ngenius-payments.com/orders/abc123")
    }

    func testInitArgsThrowWithoutAKnetLink() throws {
        let order = try TestFixtures.order(currencyCode: "KWD", cardSchemes: ["KNET"])

        assertThrows("no payment:knet link") { try order.toKnetInitArgs() }
    }
}

final class KnetCardProviderTests: XCTestCase {

    func testKnetDecodesAsItsOwnScheme() throws {
        let order = try TestFixtures.order(currencyCode: "KWD", cardSchemes: ["KNET", "VISA"])

        XCTAssertEqual(order.paymentMethods?.card, [.knet, .visa])
    }

    /// KNET is a gateway routing scheme, not a network Apple Pay can tokenise; advertising it would
    /// map to Visa on an outlet that may not accept Visa.
    func testKnetIsNotAnApplePayNetwork() {
        XCTAssertFalse(CardProvider.knet.isApplePayNetwork)
    }
}

final class KnetInitResponseTests: XCTestCase {

    /// Verbatim (IDs shortened) from UAT, 2026-11-02.
    func testReadsTheHostedPageFromASuccessfulInitiation() throws {
        let response = try TestFixtures.decode(KnetInitResponse.self, from: [
            "paymentId": "100630610000011036",
            "paymentUrl": "https://kpaytest.com.kw/kpg/paymentpage.htm?PaymentID=100630610000011036",
            "status": "Initiated"
        ])

        XCTAssertTrue(response.isInitiated)
        XCTAssertEqual(URL(string: response.paymentUrl ?? "")?.host, "kpaytest.com.kw")
    }

    /// Verbatim from UAT while the outlet's KNET encryption was broken (2026-11-02, HTTP 502).
    func testReadsTheReasonFromAGatewayRefusal() throws {
        let body = try TestFixtures.decode(KnetInitErrorBody.self, from: [
            "message": "Bad Gateway",
            "code": 502,
            "errors": [[
                "message": "Failed to encrypt KNET trandata",
                "localizedMessage": "{error.processing.invalidKnetPayment}",
                "errorCode": "invalidKnetPayment",
                "domain": "processing"
            ]]
        ])

        XCTAssertEqual(body.reason, "Failed to encrypt KNET trandata (invalidKnetPayment)")
    }
}

final class KnetPaymentStatusRoutingTests: XCTestCase {

    private func error(_ category: NIPaymentErrorCategory) -> NIPaymentError {
        return NIPaymentError(category: category, message: "reason",
                              paymentMethod: KnetViewController.methodName)
    }

    /// Cancelling on KNET's page, or leaving it before anything settled, leaves the order payable, so the
    /// payer goes back to the payment page to try again on the same order.
    func testCancellingReturnsThePayerToThePaymentPage() {
        XCTAssertTrue(KnetPaymentStatus.dismissed.returnsToPaymentPage)
        XCTAssertTrue(KnetPaymentStatus.cancelledOnProvider.returnsToPaymentPage)
    }

    func testARefusedInitiationReturnsThePayerToThePaymentPage() {
        XCTAssertTrue(KnetPaymentStatus.couldNotStart(error(.configuration)).returnsToPaymentPage)
        XCTAssertTrue(KnetPaymentStatus.couldNotStart(error(.network)).returnsToPaymentPage)
    }

    func testRealOutcomesEndThePayment() {
        XCTAssertFalse(KnetPaymentStatus.success.returnsToPaymentPage)
        XCTAssertFalse(KnetPaymentStatus.postAuthReview.returnsToPaymentPage)
        XCTAssertFalse(KnetPaymentStatus.failed(error(.declined)).returnsToPaymentPage)
        XCTAssertFalse(KnetPaymentStatus.failed(error(.timeout)).returnsToPaymentPage)
    }
}
