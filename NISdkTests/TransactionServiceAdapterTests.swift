//
//  TransactionServiceAdapterTests.swift
//  NISdkTests
//
//  Every call the SDK makes to the gateway: the URL it builds, the verb, the headers, the encoded
//  body, and how it reports success, a rejection, a transport failure and a missing link.
//

import XCTest
import PassKit
@testable import NISdk

private let jsonMediaType = "application/vnd.ni-payment.v2+json"

// MARK: - authorizePayment

final class AuthorizePaymentTests: TransactionServiceTestCase {

    private let authLink = "https://api.example.com/auth"

    /// This method reports through `[String: String]`, not `HttpResponseCallback`.
    private func authorize(code: String = "AUTH123",
                           link: String? = nil) -> [String: String] {
        let expectation = expectation(description: "tokens")
        var tokens: [String: String] = [:]
        sut.authorizePayment(for: code, using: link ?? authLink) {
            tokens = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        return tokens
    }

    func testPostsTheAuthCodeAsAFormBody() {
        _ = authorize()

        XCTAssertEqual(lastRequest.url?.absoluteString, authLink)
        XCTAssertEqual(lastRequest.httpMethod, "POST")
        XCTAssertEqual(StubURLProtocol.lastBodyString, "code=AUTH123")
        XCTAssertEqual(header("Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertEqual(header("Accept"), jsonMediaType)
    }

    func testSendsADeviceFingerprint() {
        _ = authorize()
        XCTAssertNotNil(header("X-Payer-Fingerprint"))
        XCTAssertFalse(header("X-Payer-Fingerprint")!.isEmpty)
    }

    func testTheFingerprintIsStableAcrossCallsFromTheSameAdapter() {
        _ = authorize()
        let first = header("X-Payer-Fingerprint")
        _ = authorize()
        XCTAssertEqual(header("X-Payer-Fingerprint"), first)
    }

    func testExtractsBothTokensFromSetCookie() {
        StubURLProtocol.enqueue(.init(
            statusCode: 200,
            headers: ["Set-Cookie": "access-token=acc123; Path=/,payment-token=pay456; Path=/"]))

        let tokens = authorize()

        XCTAssertEqual(tokens["access-token"], "acc123")
        XCTAssertEqual(tokens["payment-token"], "pay456")
    }

    func testReturnsNoTokensWhenTheResponseCarriesNoSetCookie() {
        StubURLProtocol.enqueue(.json("{}"))
        XCTAssertTrue(authorize().isEmpty)
    }

    func testReturnsNoTokensOnATransportFailure() {
        StubURLProtocol.enqueue(.failure(URLError(.notConnectedToInternet)))
        XCTAssertTrue(authorize().isEmpty)
    }

    func testAnUnusableLinkCompletesWithNoTokensRatherThanHanging() {
        let tokens = authorize(link: "")
        XCTAssertTrue(tokens.isEmpty)
        XCTAssertEqual(StubURLProtocol.requestCount, 0, "nothing should have been sent")
    }
}

// MARK: - getOrder

final class GetOrderRequestTests: TransactionServiceTestCase {

    private let orderLink = "https://api.example.com/orders/o1"

    func testGetsTheOrderWithABearerToken() {
        awaitResponse { sut.getOrder(for: orderLink, using: "tok", with: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, orderLink)
        XCTAssertEqual(lastRequest.httpMethod, "GET")
        XCTAssertEqual(header("Authorization"), "Bearer tok")
        XCTAssertEqual(header("Content-Type"), jsonMediaType)
    }

    func testHandsBackTheResponseBody() {
        StubURLProtocol.enqueue(.json(#"{"_id":"urn:order:o1"}"#))

        let (data, response, error) = awaitResponse { sut.getOrder(for: orderLink, using: "tok", with: $0) }

        XCTAssertNil(error)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(String(data: data!, encoding: .utf8), #"{"_id":"urn:order:o1"}"#)
    }

    func testPropagatesATransportError() {
        StubURLProtocol.enqueue(.failure(URLError(.timedOut)))

        let (_, _, error) = awaitResponse { sut.getOrder(for: orderLink, using: "tok", with: $0) }

        XCTAssertEqual((error as? URLError)?.code, .timedOut)
    }

    func testANonSuccessStatusIsPassedThroughForTheCallerToJudge() {
        StubURLProtocol.enqueue(.json(#"{"error":"unauthorised"}"#, status: 401))

        let (data, response, error) = awaitResponse { sut.getOrder(for: orderLink, using: "tok", with: $0) }

        XCTAssertNil(error, "a 401 is not a transport error")
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 401)
        XCTAssertNotNil(data)
    }

    func testAnUnusableLinkReportsMissingUrlInsteadOfHanging() {
        let (_, _, error) = awaitResponse { sut.getOrder(for: "", using: "tok", with: $0) }

        XCTAssertTrue(error is HTTPClientErrors)
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
    }
}

// MARK: - makePayment

final class MakePaymentRequestTests: TransactionServiceTestCase {

    private func order(cardLink: String? = "https://api.example.com/payments/p1/card",
                       emptyPaymentArray: Bool = false) throws -> OrderResponse {
        var links: [String: Any] = ["self": ["href": "https://api.example.com/payments/p1"]]
        if let cardLink = cardLink { links["payment:card"] = ["href": cardLink] }
        var json = TestFixtures.orderJSON(paymentLinks: links)
        if emptyPaymentArray {
            json["_embedded"] = ["payment": [[String: Any]]()]
        }
        return try OrderResponse.decodeFrom(data: try TestFixtures.data(json))
    }

    private var paymentRequest: PaymentRequest {
        PaymentRequest(pan: "4111111111111111", expiryMonth: "12", expiryYear: "30",
                       cvv: "123", cardHolderName: "John Smith")
    }

    func testPutsTheCardDetailsToTheCardPaymentLink() throws {
        let order = try order()

        awaitResponse { sut.makePayment(for: order, with: paymentRequest, using: "ptok", on: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, "https://api.example.com/payments/p1/card")
        XCTAssertEqual(lastRequest.httpMethod, "PUT")
        XCTAssertEqual(header("Authorization"), "Bearer ptok")
        XCTAssertEqual(header("Content-Type"), jsonMediaType)
    }

    func testSendsTheCardFieldsInTheBody() throws {
        let order = try order()

        awaitResponse { sut.makePayment(for: order, with: paymentRequest, using: "ptok", on: $0) }

        let body = StubURLProtocol.lastBodyJSON
        XCTAssertEqual(body?["pan"] as? String, "4111111111111111")
        XCTAssertEqual(body?["cvv"] as? String, "123")
        // The gateway's key is lowercase-h `cardholderName`, not the Swift property name.
        XCTAssertEqual(body?["cardholderName"] as? String, "John Smith")
        XCTAssertEqual(body?["expiry"] as? String, "2030-12")
        XCTAssertEqual(body?["deviceChannel"] as? String, "BRW",
                       "the gateway needs to know this came from a native app")
    }

    func testAMissingCardLinkReportsAnErrorInsteadOfHangingTheScreen() throws {
        let order = try order(cardLink: nil)

        let (_, _, error) = awaitResponse {
            sut.makePayment(for: order, with: paymentRequest, using: "ptok", on: $0)
        }

        XCTAssertTrue(error is HTTPClientErrors)
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
    }

    func testAnOrderWithNoPaymentsReportsAnErrorRatherThanTrapping() throws {
        let order = try order(emptyPaymentArray: true)

        let (_, _, error) = awaitResponse {
            sut.makePayment(for: order, with: paymentRequest, using: "ptok", on: $0)
        }

        XCTAssertTrue(error is HTTPClientErrors)
    }

    func testPropagatesADecline() throws {
        let order = try order()
        StubURLProtocol.enqueue(.json(#"{"state":"FAILED"}"#, status: 400))

        let (data, response, _) = awaitResponse {
            sut.makePayment(for: order, with: paymentRequest, using: "ptok", on: $0)
        }

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 400)
        XCTAssertNotNil(data)
    }
}

// MARK: - Apple Pay

final class ApplePayRequestTests: TransactionServiceTestCase {

    /// `PKPayment` cannot be constructed outside PassKit, so only the pre-token guard is reachable
    /// from a unit test. The request-building path is covered by the shared helpers elsewhere.
    func testAMissingApplePayLinkReportsAnErrorInsteadOfHanging() throws {
        let order = try TestFixtures.order(paymentLinks: [
            "self": ["href": "https://api.example.com/payments/p1"]
        ])

        let (_, _, error) = awaitResponse {
            sut.postApplePayResponse(for: order, with: PKPayment(), using: "tok", payerIp: nil, on: $0)
        }

        XCTAssertTrue(error is HTTPClientErrors)
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
    }
}

// MARK: - 3-D Secure 2

final class ThreeDSRequestTests: TransactionServiceTestCase {

    private func paymentResponse(authLink: String? = "https://api.example.com/3ds2/auth",
                                 challengeLink: String? = "https://api.example.com/3ds2/challenge") throws -> PaymentResponse {
        var links: [String: Any] = ["self": ["href": "https://api.example.com/payments/p1"]]
        if let authLink = authLink { links["cnp:3ds2-authentication"] = ["href": authLink] }
        if let challengeLink = challengeLink { links["cnp:3ds2-challenge-response"] = ["href": challengeLink] }
        return try TestFixtures.decode(PaymentResponse.self, from: [
            "state": "AWAIT_3DS", "reference": "p1", "_links": links
        ])
    }

    private var authRequest: ThreeDSAuthenticationsRequest {
        ThreeDSAuthenticationsRequest(threeDSCompInd: "Y",
                                      notificationURL: "https://api.example.com/notify",
                                      browserInfo: BrowserInfo())
    }

    func testPostsTheAuthenticationRequest() throws {
        let payment = try paymentResponse()

        awaitResponse {
            sut.postThreeDSAuthentications(for: payment, with: authRequest, using: "ptok", on: $0)
        }

        XCTAssertEqual(lastRequest.url?.absoluteString, "https://api.example.com/3ds2/auth")
        XCTAssertEqual(lastRequest.httpMethod, "POST")
        XCTAssertEqual(header("Authorization"), "Bearer ptok")
    }

    func testTheAuthenticationBodyCarriesTheCompletionIndicatorAndNotificationURL() throws {
        let payment = try paymentResponse()

        awaitResponse {
            sut.postThreeDSAuthentications(for: payment, with: authRequest, using: "ptok", on: $0)
        }

        let body = StubURLProtocol.lastBodyJSON
        XCTAssertEqual(body?["threeDSCompInd"] as? String, "Y")
        XCTAssertEqual(body?["notificationURL"] as? String, "https://api.example.com/notify")
        XCTAssertEqual(body?["deviceChannel"] as? String, "BRW")
    }

    func testAMissingAuthenticationLinkReportsAnError() throws {
        let payment = try paymentResponse(authLink: nil)

        let (_, _, error) = awaitResponse {
            sut.postThreeDSAuthentications(for: payment, with: authRequest, using: "ptok", on: $0)
        }

        XCTAssertTrue(error is HTTPClientErrors)
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
    }

    func testPostsTheChallengeResponseWithNoBody() throws {
        let payment = try paymentResponse()

        awaitResponse { sut.postThreeDSTwoChallengeResponse(for: payment, using: "ptok", on: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, "https://api.example.com/3ds2/challenge")
        XCTAssertEqual(lastRequest.httpMethod, "POST")
        XCTAssertNil(StubURLProtocol.lastBody)
    }

    func testAMissingChallengeLinkReportsAnError() throws {
        let payment = try paymentResponse(challengeLink: nil)

        let (_, _, error) = awaitResponse {
            sut.postThreeDSTwoChallengeResponse(for: payment, using: "ptok", on: $0)
        }

        XCTAssertTrue(error is HTTPClientErrors)
    }
}

// MARK: - payer IP

final class PayerIpRequestTests: TransactionServiceTestCase {

    private let url = "https://paypage.example.com/api/requester-ip"

    func testTheAuthenticatedVariantSendsABearerToken() {
        awaitResponse { sut.getPayerIp(with: url, using: "tok", on: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, url)
        XCTAssertEqual(lastRequest.httpMethod, "GET")
        XCTAssertEqual(header("Authorization"), "Bearer tok")
    }

    func testTheAnonymousVariantSendsNoAuthorization() {
        awaitResponse { sut.getPayerIp(with: url, on: $0) }

        XCTAssertEqual(lastRequest.httpMethod, "GET")
        XCTAssertNil(header("Authorization"))
    }

    func testAnUnusableUrlReportsAnError() {
        let (_, _, error) = awaitResponse { sut.getPayerIp(with: "", on: $0) }
        XCTAssertTrue(error is HTTPClientErrors)
    }
}

// MARK: - saved card

final class SavedCardRequestTests: TransactionServiceTestCase {

    private let url = "https://api.example.com/payments/p1/saved-card"

    private var savedCard: SavedCardRequest {
        SavedCardRequest(expiry: "2030-12", cardholderName: "John Smith",
                         cardToken: "tok-abc", cvv: "123")
    }

    func testPutsTheSavedCardWithAPaymentScopedAuthorization() {
        awaitResponse { sut.doSavedCardPayment(for: url, with: savedCard, using: "ptok", on: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, url)
        XCTAssertEqual(lastRequest.httpMethod, "PUT")
        XCTAssertEqual(header("Authorization"), "payment ptok",
                       "saved-card uses the `payment` scheme, not `Bearer`")
        XCTAssertEqual(header("Accept"), jsonMediaType)
    }

    func testSendsTheTokenAndCvvRatherThanAPan() {
        awaitResponse { sut.doSavedCardPayment(for: url, with: savedCard, using: "ptok", on: $0) }

        let body = StubURLProtocol.lastBodyJSON
        XCTAssertEqual(body?["cardToken"] as? String, "tok-abc")
        XCTAssertEqual(body?["cvv"] as? String, "123")
        XCTAssertEqual(body?["expiry"] as? String, "2030-12")
        XCTAssertNil(body?["pan"])
    }

    func testAnUnusableUrlReportsAnError() {
        let (_, _, error) = awaitResponse {
            sut.doSavedCardPayment(for: "", with: savedCard, using: "ptok", on: $0)
        }
        XCTAssertTrue(error is HTTPClientErrors)
    }
}

// MARK: - Slice

final class SliceEligibilityRequestTests: TransactionServiceTestCase {

    private let url = "https://api.example.com/payments/p1/slice"

    func testManualEntrySendsThePan() {
        awaitResponse {
            sut.checkSliceEligibility(with: url, using: "tok", pan: "4111111111111111",
                                      expiry: "2030-12", on: $0)
        }

        XCTAssertEqual(lastRequest.httpMethod, "POST")
        let body = StubURLProtocol.lastBodyJSON
        XCTAssertEqual(body?["pan"] as? String, "4111111111111111")
        XCTAssertEqual(body?["expiry"] as? String, "2030-12")
        XCTAssertNil(body?["cardToken"], "the gateway rejects a token in the pan field")
    }

    func testASavedCardSendsTheTokenInstead() {
        awaitResponse {
            sut.checkSliceEligibility(with: url, using: "tok", cardToken: "tok-abc",
                                      expiry: "2030-12", on: $0)
        }

        let body = StubURLProtocol.lastBodyJSON
        XCTAssertEqual(body?["cardToken"] as? String, "tok-abc")
        XCTAssertNil(body?["pan"])
    }

    func testSendsTheV2MediaTypeAndBearerToken() {
        awaitResponse {
            sut.checkSliceEligibility(with: url, using: "tok", pan: "4111111111111111",
                                      expiry: "2030-12", on: $0)
        }

        XCTAssertEqual(header("Authorization"), "Bearer tok")
        XCTAssertEqual(header("Accept"), jsonMediaType)
        XCTAssertEqual(header("Content-Type"), jsonMediaType)
    }

    func testAnIneligibleResponseIsHandedBackUnchanged() {
        StubURLProtocol.enqueue(.json(#"{"indicator":"N","offers":[]}"#))

        let (data, _, error) = awaitResponse {
            sut.checkSliceEligibility(with: url, using: "tok", pan: "4111111111111111",
                                      expiry: "2030-12", on: $0)
        }

        XCTAssertNil(error)
        XCTAssertTrue(String(data: data!, encoding: .utf8)!.contains("\"N\""))
    }
}

// MARK: - Visa instalments

final class VisaPlansRequestTests: TransactionServiceTestCase {

    private let url = "https://api.example.com/payments/p1"

    func testAppendsTheEligibilityCheckPath() {
        awaitResponse {
            sut.getVisaPlans(with: url, using: "tok", cardToken: nil,
                             cardNumber: "4111111111111111", on: $0)
        }

        XCTAssertEqual(lastRequest.url?.absoluteString,
                       "https://api.example.com/payments/p1/vis/eligibility-check")
        XCTAssertEqual(lastRequest.httpMethod, "POST")
    }

    func testSendsThePanWhenThereIsNoToken() {
        awaitResponse {
            sut.getVisaPlans(with: url, using: "tok", cardToken: nil,
                             cardNumber: "4111111111111111", on: $0)
        }

        XCTAssertEqual(StubURLProtocol.lastBodyJSON?["pan"] as? String, "4111111111111111")
    }

    func testSendsTheTokenForASavedCard() {
        awaitResponse {
            sut.getVisaPlans(with: url, using: "tok", cardToken: "tok-abc", cardNumber: nil, on: $0)
        }

        XCTAssertEqual(StubURLProtocol.lastBodyJSON?["cardToken"] as? String, "tok-abc")
    }
}

// MARK: - partial auth

final class PartialAuthRequestTests: TransactionServiceTestCase {

    func testPutsToTheGivenUrl() {
        awaitResponse { sut.partialAuth(with: "https://api.example.com/accept", using: "tok", on: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, "https://api.example.com/accept")
        XCTAssertEqual(lastRequest.httpMethod, "PUT")
        XCTAssertEqual(header("Authorization"), "Bearer tok")
    }

    func testAnUnusableUrlReportsAnError() {
        let (_, _, error) = awaitResponse { sut.partialAuth(with: "", using: "tok", on: $0) }
        XCTAssertTrue(error is HTTPClientErrors)
    }
}

// MARK: - Aani

final class AaniRequestTests: TransactionServiceTestCase {

    private let payLink = "https://api.example.com/payments/p1/aani"
    private let qrLink = "https://api.example.com/payments/p1/aani-qr"

    private var aaniRequest: AaniPayRequest {
        let request = AaniPayRequest(aliasType: "MOBILE_NUMBER", payerIp: "1.1.1.1",
                                     backLink: "https://merchant.example.com/return")
        request.mobileNumber = MobileNumber(countryCode: "971", number: "500000000")
        return request
    }

    func testPostsTheAliasPayment() {
        awaitResponse { sut.aaniPayment(for: payLink, with: aaniRequest, using: "tok", on: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, payLink)
        XCTAssertEqual(lastRequest.httpMethod, "POST")
        XCTAssertEqual(header("Authorization"), "Bearer tok")

        let body = StubURLProtocol.lastBodyJSON
        XCTAssertEqual(body?["aliasType"] as? String, "MOBILE_NUMBER")
        XCTAssertEqual(body?["source"] as? String, "MOBILE_APP")
        XCTAssertEqual((body?["mobileNumber"] as? [String: Any])?["number"] as? String, "500000000")
    }

    func testPollsTheAliasPaymentStatus() {
        awaitResponse { sut.aaniPaymentPooling(with: payLink + "/status", using: "tok", on: $0) }

        XCTAssertEqual(lastRequest.httpMethod, "GET")
        XCTAssertEqual(header("Authorization"), "Bearer tok")
    }

    func testCreatesAQrWithAnEmptyJsonBody() {
        awaitResponse { sut.aaniQrCreate(for: qrLink, using: "tok", on: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, qrLink)
        XCTAssertEqual(lastRequest.httpMethod, "POST")
        XCTAssertEqual(StubURLProtocol.lastBodyString, "{}",
                       "the backend rejects a missing body on QR create")
    }

    func testPollsTheQrStatusWithBothIdentifiers() {
        awaitResponse {
            sut.aaniQrPollStatus(with: qrLink, qrCodeId: "qr-1", qrTransactionId: "qrtx-1",
                                 using: "tok", on: $0)
        }

        XCTAssertEqual(lastRequest.url?.absoluteString,
                       "\(qrLink)/status?qrCodeId=qr-1&qrTransactionId=qrtx-1")
        XCTAssertEqual(lastRequest.httpMethod, "GET")
    }

    func testCancelsTheQrWithBothIdentifiers() {
        awaitResponse {
            sut.aaniQrCancel(with: qrLink, qrCodeId: "qr-1", qrTransactionId: "qrtx-1",
                             using: "tok", on: $0)
        }

        XCTAssertEqual(lastRequest.url?.absoluteString,
                       "\(qrLink)?qrCodeId=qr-1&qrTransactionId=qrtx-1")
        XCTAssertEqual(lastRequest.httpMethod, "DELETE")
    }

    func testAQrPollCanReportATerminalStatus() {
        StubURLProtocol.enqueue(.json(#"{"state":"CAPTURED"}"#))

        let (data, _, _) = awaitResponse {
            sut.aaniQrPollStatus(with: qrLink, qrCodeId: "qr-1", qrTransactionId: "qrtx-1",
                                 using: "tok", on: $0)
        }

        XCTAssertTrue(String(data: data!, encoding: .utf8)!.contains("CAPTURED"))
    }

    func testAnUnusableAaniLinkReportsAnError() {
        let (_, _, error) = awaitResponse {
            sut.aaniPayment(for: "", with: aaniRequest, using: "tok", on: $0)
        }
        XCTAssertTrue(error is HTTPClientErrors)
    }
}

// MARK: - QPay and Benefit

final class QPayAndBenefitRequestTests: TransactionServiceTestCase {

    private let qpayLink = "https://api.example.com/payments/p1/qpay"
    private let benefitLink = "https://api.example.com/payments/p1/benefit"

    func testInitQPayPostsAnEmptyJsonBody() {
        awaitResponse { sut.initQPay(with: qpayLink, using: "tok", on: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, qpayLink)
        XCTAssertEqual(lastRequest.httpMethod, "POST")
        XCTAssertEqual(StubURLProtocol.lastBodyString, "{}",
                       "the backend rejects a missing body with 'initiatePaymentRequest is null'")
        XCTAssertEqual(header("Authorization"), "Bearer tok")
    }

    func testInitQPayHandsBackTheFormFields() {
        StubURLProtocol.enqueue(.json(#"{"redirectUri":"https://qcb.example.com/pay","Amount":500}"#))

        let (data, _, error) = awaitResponse { sut.initQPay(with: qpayLink, using: "tok", on: $0) }

        XCTAssertNil(error)
        let decoded = try? JSONDecoder().decode(QPayInitResponse.self, from: data!)
        XCTAssertEqual(decoded?.redirectUri, "https://qcb.example.com/pay")
        XCTAssertEqual(decoded?.amount, "500")
    }

    func testInitBenefitSendsTheV2AcceptHeader() {
        awaitResponse { sut.initBenefit(with: benefitLink, using: "tok", on: $0) }

        XCTAssertEqual(lastRequest.url?.absoluteString, benefitLink)
        XCTAssertEqual(lastRequest.httpMethod, "POST")
        XCTAssertEqual(header("Accept"), jsonMediaType)
        XCTAssertEqual(header("Content-Type"), jsonMediaType)
        XCTAssertEqual(StubURLProtocol.lastBodyString, "{}")
    }

    func testABenefitRejectionIsReportedWithItsBody() {
        StubURLProtocol.enqueue(.json(#"{"status":"Failed","errorMessage":"card not enrolled"}"#, status: 400))

        let (data, response, error) = awaitResponse { sut.initBenefit(with: benefitLink, using: "tok", on: $0) }

        XCTAssertNil(error)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 400)
        XCTAssertTrue(String(data: data!, encoding: .utf8)!.contains("card not enrolled"))
    }

    func testAnUnusableQPayLinkReportsAnError() {
        let (_, _, error) = awaitResponse { sut.initQPay(with: "", using: "tok", on: $0) }
        XCTAssertTrue(error is HTTPClientErrors)
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
    }
}

// MARK: - cross-cutting

final class TransportBehaviourTests: TransactionServiceTestCase {

    private let url = "https://api.example.com/orders/o1"

    func testEveryRequestIdentifiesTheSDKInItsUserAgent() {
        awaitResponse { sut.getOrder(for: url, using: "tok", with: $0) }

        let userAgent = header("User-Agent")
        XCTAssertNotNil(userAgent)
        XCTAssertTrue(userAgent!.contains("iOS pay page"))
        XCTAssertTrue(userAgent!.contains(NISdk.sharedInstance.version))
    }

    func testAnEmptyBodyOnSuccessIsNotAnError() {
        StubURLProtocol.enqueue(.init(statusCode: 204))

        let (_, response, error) = awaitResponse { sut.getOrder(for: url, using: "tok", with: $0) }

        XCTAssertNil(error)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 204)
    }

    func testEachCallIssuesExactlyOneRequest() {
        awaitResponse { sut.getOrder(for: url, using: "tok", with: $0) }
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
    }

    func testAServerErrorReachesTheCallerRatherThanBeingSwallowed() {
        StubURLProtocol.enqueue(.json("<html>502</html>", status: 502))

        let (data, response, error) = awaitResponse { sut.getOrder(for: url, using: "tok", with: $0) }

        XCTAssertNil(error)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 502)
        XCTAssertNotNil(data, "the body must survive so callers can log what the gateway said")
    }
}
