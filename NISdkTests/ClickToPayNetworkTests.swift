//
//  ClickToPayNetworkTests.swift
//  NISdkTests
//
//  The two Click to Pay callers that reach the network outside TransactionServiceAdapter.
//

import XCTest
@testable import NISdk

final class ClickToPayMerchantConfigServiceTests: TransactionServiceTestCase {

    private func fetch(merchantId: String = "merch-1",
                       base: String = "https://api-gateway.sandbox.ngenius-payments.com")
    -> Result<ClickToPayMerchantConfigService.Resolved, ClickToPayMerchantConfigService.FetchError> {
        let expectation = expectation(description: "config")
        var outcome: Result<ClickToPayMerchantConfigService.Resolved,
                            ClickToPayMerchantConfigService.FetchError>!
        ClickToPayMerchantConfigService.fetch(merchantId: merchantId,
                                              accessToken: "tok",
                                              apiGatewayBaseUrl: base) {
            outcome = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        return outcome
    }

    func testBuildsTheVctpConfigPath() {
        StubURLProtocol.enqueue(.json(#"{"dpaId":"dpa-1"}"#))

        _ = fetch()

        XCTAssertEqual(lastRequest.url?.absoluteString,
                       "https://api-gateway.sandbox.ngenius-payments.com/config/merchants/merch-1/configs/vctp")
        XCTAssertEqual(lastRequest.httpMethod, "GET")
        XCTAssertEqual(header("Authorization"), "Bearer tok")
    }

    func testATrailingSlashOnTheBaseUrlIsNotDoubled() {
        StubURLProtocol.enqueue(.json(#"{"dpaId":"dpa-1"}"#))

        _ = fetch(base: "https://api-gateway.sandbox.ngenius-payments.com/")

        XCTAssertEqual(lastRequest.url?.absoluteString,
                       "https://api-gateway.sandbox.ngenius-payments.com/config/merchants/merch-1/configs/vctp")
    }

    func testResolvesTheDpaCredentials() throws {
        StubURLProtocol.enqueue(.json("""
        {"dpaId":"dpa-1","dpaClientId":"client-1",
         "successResponse":{"companyPrimaryLegalName":"Test Merchant Ltd"}}
        """))

        let resolved = try fetch().get()

        XCTAssertEqual(resolved.dpaId, "dpa-1")
        XCTAssertEqual(resolved.dpaClientId, "client-1")
        XCTAssertEqual(resolved.dpaName, "Test Merchant Ltd")
    }

    func testOptionalFieldsMayBeAbsent() throws {
        StubURLProtocol.enqueue(.json(#"{"dpaId":"dpa-1"}"#))

        let resolved = try fetch().get()

        XCTAssertEqual(resolved.dpaId, "dpa-1")
        XCTAssertNil(resolved.dpaClientId)
        XCTAssertNil(resolved.dpaName)
    }

    func testAResponseWithoutADpaIdIsRejected() {
        StubURLProtocol.enqueue(.json(#"{"dpaClientId":"client-1"}"#))

        guard case .failure(let error) = fetch() else { return XCTFail("expected a failure") }
        guard case .missingDpaId = error else { return XCTFail("expected missingDpaId, got \(error)") }
    }

    func testAnEmptyDpaIdIsRejected() {
        StubURLProtocol.enqueue(.json(#"{"dpaId":""}"#))

        guard case .failure(let error) = fetch() else { return XCTFail("expected a failure") }
        guard case .missingDpaId = error else { return XCTFail("expected missingDpaId, got \(error)") }
    }

    func testANonJsonBodyIsReportedAsNoData() {
        StubURLProtocol.enqueue(.json("<html>502</html>", status: 502))

        guard case .failure(let error) = fetch() else { return XCTFail("expected a failure") }
        guard case .noData = error else { return XCTFail("expected noData, got \(error)") }
    }

    func testATransportFailureIsWrapped() {
        StubURLProtocol.enqueue(.failure(URLError(.notConnectedToInternet)))

        guard case .failure(let error) = fetch() else { return XCTFail("expected a failure") }
        guard case .underlying = error else { return XCTFail("expected underlying, got \(error)") }
    }

    /// An empty base still produces a parseable *relative* path, so the `invalidUrl` guard never
    /// fires through this API — the misconfiguration surfaces from the transport instead. Pinned
    /// here so the guard is not mistaken for input validation.
    func testAnEmptyBaseUrlStillBuildsARelativePathRatherThanBeingRejected() {
        StubURLProtocol.enqueue(.json(#"{"dpaId":"dpa-1"}"#))

        _ = fetch(base: "")

        XCTAssertEqual(StubURLProtocol.requestCount, 1)
        XCTAssertNil(lastRequest.url?.host)
        XCTAssertEqual(lastRequest.url?.path, "/config/merchants/merch-1/configs/vctp")
    }
}

final class ClickToPayApiInteractorTests: TransactionServiceTestCase {

    private let sutInteractor = ClickToPayApiInteractor()
    private let url = "https://api.example.com/api/outlets/o1/orders/ord1/payments/p1/unified-click-to-pay"

    private func submit(url overrideUrl: String? = nil,
                        srcDigitalCardId: String? = nil,
                        cookie: String = "payment-token=ptok") -> ClickToPayPaymentResult {
        let expectation = expectation(description: "payment")
        var result: ClickToPayPaymentResult!
        sutInteractor.submitPayment(unifiedClickToPayUrl: overrideUrl ?? url,
                                    checkoutResponse: "checkout-blob",
                                    srcDigitalCardId: srcDigitalCardId,
                                    accessToken: "atok",
                                    paymentCookie: cookie) {
            result = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        return result
    }

    // MARK: request shape

    func testPostsTheCheckoutResponse() {
        StubURLProtocol.enqueue(.json(#"{"state":"CAPTURED"}"#))

        _ = submit()

        XCTAssertEqual(lastRequest.url?.absoluteString, url)
        XCTAssertEqual(lastRequest.httpMethod, "POST")
        XCTAssertEqual(StubURLProtocol.lastBodyJSON?["checkoutResponse"] as? String, "checkout-blob")
    }

    func testOmitsTheDigitalCardIdWhenThereIsNone() {
        StubURLProtocol.enqueue(.json(#"{"state":"CAPTURED"}"#))

        _ = submit()

        XCTAssertNil(StubURLProtocol.lastBodyJSON?["srcDigitalCardId"])
    }

    func testIncludesTheDigitalCardIdWhenGiven() {
        StubURLProtocol.enqueue(.json(#"{"state":"CAPTURED"}"#))

        _ = submit(srcDigitalCardId: "card-9")

        XCTAssertEqual(StubURLProtocol.lastBodyJSON?["srcDigitalCardId"] as? String, "card-9")
    }

    func testSendsBothTokenHeadersAndTheCookie() {
        StubURLProtocol.enqueue(.json(#"{"state":"CAPTURED"}"#))

        _ = submit()

        XCTAssertEqual(header("Authorization"), "Bearer atok")
        XCTAssertEqual(header("Access-Token"), "atok")
        XCTAssertEqual(header("Cookie"), "payment-token=ptok")
        XCTAssertEqual(header("Payment-Token"), "ptok", "the value is split out of the cookie")
    }

    func testAPaymentTokenContainingEqualsIsKeptWhole() {
        StubURLProtocol.enqueue(.json(#"{"state":"CAPTURED"}"#))

        _ = submit(cookie: "payment-token=abc==")

        XCTAssertEqual(header("Payment-Token"), "abc==", "base64 padding must survive the split")
    }

    // MARK: response mapping

    func testMapsEachTerminalState() {
        let cases: [(String, String)] = [
            ("AUTHORISED", "authorised"), ("PURCHASED", "purchased"),
            ("CAPTURED", "captured"), ("POST_AUTH_REVIEW", "postAuthReview")
        ]
        for (state, expected) in cases {
            StubURLProtocol.reset()
            StubURLProtocol.enqueue(.json(#"{"state":"\#(state)"}"#))
            XCTAssertEqual(label(of: submit()), expected, "wrong mapping for \(state)")
        }
    }

    func testAwaitingThreeDSAndPendingBothMeanKeepPolling() {
        for state in ["AWAIT_3DS", "PENDING"] {
            StubURLProtocol.reset()
            StubURLProtocol.enqueue(.json(#"{"state":"\#(state)"}"#))
            XCTAssertEqual(label(of: submit()), "pending", "wrong mapping for \(state)")
        }
    }

    func testAFailedStateCarriesTheGatewayMessage() {
        StubURLProtocol.enqueue(.json(#"{"state":"FAILED","message":"Insufficient funds"}"#))

        guard case .failed(let message) = submit() else { return XCTFail("expected failed") }
        XCTAssertEqual(message, "Insufficient funds")
    }

    func testAFailedStateWithoutAMessageStillReports() {
        StubURLProtocol.enqueue(.json(#"{"state":"FAILED"}"#))

        guard case .failed(let message) = submit() else { return XCTFail("expected failed") }
        XCTAssertEqual(message, "Payment failed")
    }

    func testAnUnrecognisedStateIsReportedRatherThanSilentlyPassing() {
        StubURLProtocol.enqueue(.json(#"{"state":"SOMETHING_NEW"}"#))

        guard case .failed(let message) = submit() else { return XCTFail("expected failed") }
        XCTAssertTrue(message.contains("SOMETHING_NEW"))
    }

    func testANonJsonBodyIsReportedAsAFailure() {
        StubURLProtocol.enqueue(.json("<html>502</html>", status: 502))

        guard case .failed = submit() else { return XCTFail("expected failed") }
    }

    func testATransportFailureIsReported() {
        StubURLProtocol.enqueue(.failure(URLError(.notConnectedToInternet)))

        guard case .failed = submit() else { return XCTFail("expected failed") }
    }

    func testAnUnusableUrlFailsInsteadOfHanging() {
        guard case .failed = submit(url: "") else { return XCTFail("expected failed") }
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
    }

    // MARK: url building

    func testBuildsTheUnifiedUrlFromAnApiPaymentUrl() {
        let built = ClickToPayApiInteractor.buildUnifiedClickToPayUrl(
            basePaymentUrl: "https://api.example.com/api/outlets/o1/orders/ord1/payments/p1",
            outletId: "o1", orderId: "ord1", paymentRef: "p1")

        XCTAssertEqual(built, "https://api.example.com/api/outlets/o1/orders/ord1/payments/p1/unified-click-to-pay")
    }

    func testBuildsTheUnifiedUrlFromATransactionsUrl() {
        let built = ClickToPayApiInteractor.buildUnifiedClickToPayUrl(
            basePaymentUrl: "https://api.example.com/transactions/outlets/o1",
            outletId: "o1", orderId: "ord1", paymentRef: "p1")

        XCTAssertEqual(built, "https://api.example.com/api/outlets/o1/orders/ord1/payments/p1/unified-click-to-pay")
    }

    func testABaseWithNeitherMarkerIsUsedAsIs() {
        let built = ClickToPayApiInteractor.buildUnifiedClickToPayUrl(
            basePaymentUrl: "https://api.example.com",
            outletId: "o1", orderId: "ord1", paymentRef: "p1")

        XCTAssertEqual(built, "https://api.example.com/api/outlets/o1/orders/ord1/payments/p1/unified-click-to-pay")
    }

    private func label(of result: ClickToPayPaymentResult) -> String {
        switch result {
        case .authorised: return "authorised"
        case .purchased: return "purchased"
        case .captured: return "captured"
        case .postAuthReview: return "postAuthReview"
        case .pending: return "pending"
        case .requires3DS: return "requires3DS"
        case .failed(let message): return "failed(\(message))"
        }
    }
}
