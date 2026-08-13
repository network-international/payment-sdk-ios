//
//  OrderResponseTests.swift
//  NISdkTests
//
//  Decoding of the gateway's order payload and the argument mappers each
//  payment method uses to pull what it needs out of that order.
//

import XCTest
@testable import NISdk

final class OrderResponseDecodingTests: XCTestCase {

    func testDecodesTheFieldsTheSDKRelieson() throws {
        let order = try TestFixtures.order()

        XCTAssertEqual(order._id, "urn:order:abc123")
        XCTAssertEqual(order.action, "PURCHASE")
        XCTAssertEqual(order.amount?.currencyCode, "AED")
        XCTAssertEqual(order.amount?.value, 5000)
        XCTAssertEqual(order.outletId, "outlet-1")
    }

    func testHalLinksAreFlattenedToTheirHrefs() throws {
        let order = try TestFixtures.order()

        XCTAssertEqual(order.orderLinks?.orderLink, "https://api.sandbox.ngenius-payments.com/orders/abc123")
        XCTAssertEqual(order.orderLinks?.paymentAuthorizationLink, "https://api.sandbox.ngenius-payments.com/auth")
        XCTAssertEqual(order.embeddedData?.getQPayLink(),
                       "https://api.sandbox.ngenius-payments.com/payments/pay123/qpay")
        XCTAssertEqual(order.embeddedData?.getAaniPayLink(),
                       "https://api.sandbox.ngenius-payments.com/payments/pay123/aani")
        XCTAssertEqual(order.embeddedData?.getClickToPayLink(),
                       "https://api.sandbox.ngenius-payments.com/payments/pay123/ctp")
        XCTAssertEqual(order.embeddedData?.getSliceEligibilityCheckLink(),
                       "https://api.sandbox.ngenius-payments.com/payments/pay123/slice")
    }

    func testAbsentLinksDecodeToNilRatherThanThrowing() throws {
        let order = try TestFixtures.order(paymentLinks: [
            "self": ["href": "https://api.sandbox.ngenius-payments.com/payments/pay123"]
        ])

        XCTAssertNil(order.embeddedData?.getQPayLink())
        XCTAssertNil(order.embeddedData?.getAaniPayLink())
        XCTAssertEqual(order.embeddedData?.getSelfLink(),
                       "https://api.sandbox.ngenius-payments.com/payments/pay123")
    }

    func testMissingIdFallsBackToEmptyString() throws {
        var json = TestFixtures.orderJSON()
        json.removeValue(forKey: "_id")
        let order = try OrderResponse.decodeFrom(data: try TestFixtures.data(json))
        XCTAssertEqual(order._id, "")
    }

    func testMissingActionIsAHardDecodingFailure() throws {
        var json = TestFixtures.orderJSON()
        json.removeValue(forKey: "action")
        XCTAssertThrowsError(try OrderResponse.decodeFrom(data: try TestFixtures.data(json)))
    }

    func testUnknownCardSchemeIsSkippedRatherThanFailingTheOrder() throws {
        let order = try TestFixtures.order(cardSchemes: ["VISA", "SOME_NEW_SCHEME", "MASTERCARD"])
        XCTAssertEqual(order.paymentMethods?.card, [.visa, .masterCard])
    }

    func testMalformedJSONThrows() {
        XCTAssertThrowsError(try OrderResponse.decodeFrom(data: Data("not json".utf8)))
    }
}

final class OrderResponseAuthCodeTests: XCTestCase {

    func testReadsTheCodeQueryParameterFromThePayPageLink() throws {
        let order = try TestFixtures.order()
        XCTAssertEqual(order.getAuthCode(), "AUTHCODE123")
    }

    func testReturnsNilWhenThePayPageLinkCarriesNoCode() throws {
        let order = try TestFixtures.order(payPageHref: "https://paypage.sandbox.ngenius-payments.com/")
        XCTAssertNil(order.getAuthCode())
    }

    func testReturnsNilWhenThereIsNoPayPageLinkAtAll() {
        XCTAssertNil(OrderResponse().getAuthCode())
    }
}

final class OrderResponseBenefitTests: XCTestCase {

    func testBenefitIsOfferedForABHDPurchaseOnABenefitEnabledOutlet() throws {
        let order = try TestFixtures.order(action: "PURCHASE", currencyCode: "BHD",
                                           cardSchemes: ["VISA", "BENEFIT"])
        XCTAssertTrue(order.isBenefitSupported)
    }

    func testActionComparisonIsCaseInsensitive() throws {
        let order = try TestFixtures.order(action: "purchase", currencyCode: "bhd",
                                           cardSchemes: ["BENEFIT"])
        XCTAssertTrue(order.isBenefitSupported)
    }

    func testBenefitIsHiddenWhenTheOutletDoesNotListIt() throws {
        let order = try TestFixtures.order(action: "PURCHASE", currencyCode: "BHD",
                                           cardSchemes: ["VISA"])
        XCTAssertFalse(order.isBenefitSupported)
    }

    func testBenefitIsHiddenForANonBHDOrder() throws {
        let order = try TestFixtures.order(action: "PURCHASE", currencyCode: "AED",
                                           cardSchemes: ["BENEFIT"])
        XCTAssertFalse(order.isBenefitSupported)
    }

    func testBenefitIsHiddenForANonPurchaseAction() throws {
        for action in ["AUTH", "SALE"] {
            let order = try TestFixtures.order(action: action, currencyCode: "BHD",
                                               cardSchemes: ["BENEFIT"])
            XCTAssertFalse(order.isBenefitSupported, "\(action) must not offer Benefit")
        }
    }

    func testInitArgsDeriveTheBenefitEndpointFromThePaymentSelfLink() throws {
        let order = try TestFixtures.order(action: "PURCHASE", currencyCode: "BHD",
                                           cardSchemes: ["BENEFIT"])
        let args = try order.toBenefitInitArgs()

        XCTAssertEqual(args.benefitLink, "https://api.sandbox.ngenius-payments.com/payments/pay123/benefit")
        XCTAssertEqual(args.orderLink, "https://api.sandbox.ngenius-payments.com/orders/abc123")
    }

    func testTrailingSlashOnThePaymentLinkIsNotDoubled() throws {
        let order = try TestFixtures.order(
            action: "PURCHASE", currencyCode: "BHD", cardSchemes: ["BENEFIT"],
            paymentLinks: ["self": ["href": "https://api.example.com/payments/pay123/"]])

        XCTAssertEqual(try order.toBenefitInitArgs().benefitLink,
                       "https://api.example.com/payments/pay123/benefit")
    }

    func testInitArgsThrowWhenThePaymentSelfLinkIsMissing() throws {
        let order = try TestFixtures.order(
            action: "PURCHASE", currencyCode: "BHD", cardSchemes: ["BENEFIT"],
            paymentLinks: ["payment:card": ["href": "https://api.example.com/card"]])

        XCTAssertThrowsError(try order.toBenefitInitArgs())
    }

    func testSupportedCurrencyIsBHD() {
        XCTAssertEqual(BenefitInitArgs.supportedCurrency, "BHD")
    }
}

final class OrderResponseQPayArgsTests: XCTestCase {

    func testMapsEveryFieldQPayNeeds() throws {
        let order = try TestFixtures.order()
        let args = try order.toQPayInitArgs()

        XCTAssertEqual(args.qpayLink, "https://api.sandbox.ngenius-payments.com/payments/pay123/qpay")
        XCTAssertEqual(args.orderLink, "https://api.sandbox.ngenius-payments.com/orders/abc123")
        XCTAssertEqual(args.authUrl, "https://api.sandbox.ngenius-payments.com/auth")
        XCTAssertEqual(args.authCode, "AUTHCODE123")
        XCTAssertEqual(args.currencyCode, "AED")
    }

    func testPayPageOriginIsSchemeAndHostOnly() throws {
        let order = try TestFixtures.order(
            payPageHref: "https://paypage-sandbox.platform.network.ae/pay/long/path?code=XYZ")

        XCTAssertEqual(try order.toQPayInitArgs().payPageOrigin,
                       "https://paypage-sandbox.platform.network.ae/",
                       "the QCB form POST is whitelisted by origin, so query and path must be dropped")
    }

    func testThrowsWhenTheQPayLinkIsMissing() throws {
        let order = try TestFixtures.order(paymentLinks: [
            "self": ["href": "https://api.example.com/payments/pay123"]
        ])
        XCTAssertThrowsError(try order.toQPayInitArgs())
    }

    func testThrowsWhenTheAuthCodeIsMissing() throws {
        let order = try TestFixtures.order(payPageHref: "https://paypage.example.com/")
        XCTAssertThrowsError(try order.toQPayInitArgs())
    }
}

final class OrderResponseAaniArgsTests: XCTestCase {

    func testMapsEveryFieldAaniNeeds() throws {
        let order = try TestFixtures.order()
        let args = try order.toAaniPayArgs("https://merchant.example.com/return", accessToken: "tok-1")

        XCTAssertEqual(args.amount, 5000)
        XCTAssertEqual(args.currencyCode, "AED")
        XCTAssertEqual(args.anniPaymentLink, "https://api.sandbox.ngenius-payments.com/payments/pay123/aani")
        XCTAssertEqual(args.anniQrPaymentLink, "https://api.sandbox.ngenius-payments.com/payments/pay123/aani-qr")
        XCTAssertEqual(args.backLink, "https://merchant.example.com/return")
        XCTAssertEqual(args.authCode, "AUTHCODE123")
        XCTAssertEqual(args.accessToken, "tok-1")
    }

    func testQrLinkFallsBackToEmptyWhenTheOutletHasNoQrRel() throws {
        var links = TestFixtures.defaultPaymentLinks()
        links.removeValue(forKey: "payment:aani-qr")
        let order = try TestFixtures.order(paymentLinks: links)

        XCTAssertEqual(try order.toAaniPayArgs("back").anniQrPaymentLink, "")
    }

    func testThrowsWhenTheAaniLinkIsMissing() throws {
        let order = try TestFixtures.order(paymentLinks: [
            "self": ["href": "https://api.example.com/payments/pay123"]
        ])
        XCTAssertThrowsError(try order.toAaniPayArgs("back"))
    }

    func testAccessTokenIsOptional() throws {
        let order = try TestFixtures.order()
        XCTAssertNil(try order.toAaniPayArgs("back").accessToken)
    }
}

final class OrderResponsePartialAuthArgsTests: XCTestCase {

    private func partiallyAuthorisedOrder() throws -> OrderResponse {
        var links = TestFixtures.defaultPaymentLinks()
        links["payment:partial-auth-accept"] = ["href": "https://api.example.com/accept"]
        links["payment:partial-auth-decline"] = ["href": "https://api.example.com/decline"]
        return try TestFixtures.order(
            paymentLinks: links,
            paymentExtras: [
                "authResponse": ["amount": 5000, "partialAmount": 3000],
                "paymentMethod": ["issuingOrg": "Test Bank"]
            ])
    }

    func testMapsAmountsLinksAndToken() throws {
        let args = try partiallyAuthorisedOrder().toPartialAuthArgs(accessToken: "tok-9")

        XCTAssertEqual(args.amount, 5000)
        XCTAssertEqual(args.partialAmount, 3000)
        XCTAssertEqual(args.currency, "AED")
        XCTAssertEqual(args.acceptUrl, "https://api.example.com/accept")
        XCTAssertEqual(args.declineUrl, "https://api.example.com/decline")
        XCTAssertEqual(args.accessToken, "tok-9")
    }

    func testThrowsWithoutAnAccessToken() throws {
        XCTAssertThrowsError(try partiallyAuthorisedOrder().toPartialAuthArgs(accessToken: nil))
    }

    func testThrowsWhenTheOrderWasNeverPartiallyAuthorised() throws {
        let order = try TestFixtures.order()
        XCTAssertThrowsError(try order.toPartialAuthArgs(accessToken: "tok-9"))
    }
}

final class OrderResponseBuilderTests: XCTestCase {

    func testBuilderSetsOnlyWhatItIsGiven() {
        let order = OrderResponse.Builder()
            .withId(_id: "urn:order:xyz")
            .withAction(action: "SALE")
            .build()

        XCTAssertEqual(order._id, "urn:order:xyz")
        XCTAssertEqual(order.action, "SALE")
        XCTAssertNil(order.amount)
        XCTAssertNil(order.orderLinks)
    }
}
