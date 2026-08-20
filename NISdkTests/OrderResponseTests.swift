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

final class OrderResponseBnplTests: XCTestCase {

    /// Mirrors what the gateway actually returns for a BNPL-enabled outlet: the providers under
    /// `paymentMethods.apm`, each with its own `payment:{provider}` rel.
    private func bnplOrder(apm: [String],
                           rels: [BnplProvider] = BnplProvider.allCases,
                           currencyCode: String = "AED",
                           value: Double = 50000) throws -> OrderResponse {
        var links = TestFixtures.defaultPaymentLinks()
        for provider in rels {
            links[provider.linkRel] = ["href": "https://api.sandbox.ngenius-payments.com/payments/pay123/\(provider.pathSegment)"]
        }
        return try TestFixtures.order(
            currencyCode: currencyCode,
            value: value,
            paymentLinks: links,
            overrides: ["paymentMethods": ["card": ["VISA"], "wallet": [], "apm": apm]])
    }

    func testEachProviderIsOfferedWhenTheOrderListsIt() throws {
        XCTAssertEqual(try bnplOrder(apm: ["TAMARA"]).supportedBnplProviders, [.tamara])
        XCTAssertEqual(try bnplOrder(apm: ["TABBY"]).supportedBnplProviders, [.tabby])
    }

    /// The live DEV order carries all three APMs together; both BNPL providers must survive that.
    func testBothProvidersAreOfferedAlongsideOtherApms() throws {
        let order = try bnplOrder(apm: ["TABBY", "AANI", "TAMARA"])
        XCTAssertEqual(order.supportedBnplProviders, [.tamara, .tabby])
    }

    func testApmComparisonIsCaseInsensitive() throws {
        XCTAssertEqual(try bnplOrder(apm: ["tamara", "tabby"]).supportedBnplProviders, [.tamara, .tabby])
    }

    func testNothingIsOfferedWhenTheOrderListsNoBnplApms() throws {
        XCTAssertTrue(try bnplOrder(apm: ["AANI"]).supportedBnplProviders.isEmpty)
        XCTAssertTrue(try TestFixtures.order().supportedBnplProviders.isEmpty)
    }

    /// An unknown APM must not stop the known ones decoding — the gateway adds them without an SDK
    /// release.
    func testUnknownApmsAreKeptRatherThanFailingTheOrder() throws {
        let order = try bnplOrder(apm: ["SOMETHING_NEW", "TAMARA"])
        XCTAssertEqual(order.paymentMethods?.apm, ["SOMETHING_NEW", "TAMARA"])
        XCTAssertEqual(order.supportedBnplProviders, [.tamara])
    }

    /// A basket under the provider's minimum must not remove the row: an option the outlet enables
    /// and the payer cannot find reads as the SDK being broken. It stays, and says why.
    func testABasketBelowTheMinimumStillOffersTheRow() throws {
        let order = try bnplOrder(apm: ["TAMARA", "TABBY"], currencyCode: "AED", value: 500)
        XCTAssertEqual(order.supportedBnplProviders, [.tamara, .tabby])
        XCTAssertTrue(order.isBelowBnplMinimum(for: .tabby))
    }

    func testTheMinimumIsClearedExactlyAtTheThreshold() throws {
        let order = try bnplOrder(apm: ["TABBY"], currencyCode: "AED", value: 1000)
        XCTAssertFalse(order.isBelowBnplMinimum(for: .tabby))
    }

    /// The minimum is quoted in AED only, so another currency is left to the gateway to judge.
    func testTheAedMinimumDoesNotLeakIntoOtherCurrencies() throws {
        let order = try bnplOrder(apm: ["TABBY"], currencyCode: "SAR", value: 500)
        XCTAssertFalse(order.isBelowBnplMinimum(for: .tabby))
        XCTAssertNil(order.formattedBnplMinimum(for: .tabby))
    }

    /// Tamara publishes no minimum, so nothing is invented for it.
    func testTamaraHasNoMinimumOfItsOwn() throws {
        let order = try bnplOrder(apm: ["TAMARA"], currencyCode: "AED", value: 1)
        XCTAssertFalse(order.isBelowBnplMinimum(for: .tamara))
        XCTAssertNil(order.formattedBnplMinimum(for: .tamara))
    }

    func testTheMinimumIsFormattedForDisplayInTheOrdersCurrency() throws {
        let order = try bnplOrder(apm: ["TABBY"], currencyCode: "AED", value: 500)
        XCTAssertEqual(order.formattedBnplMinimum(for: .tabby), "AED 10")
    }

    /// BHD carries three minor digits, so a naive divide-by-100 would read 500 as 5.000 and clear a
    /// threshold it does not actually meet.
    func testMinorUnitsAreRespectedWhenComparing() throws {
        let order = try bnplOrder(apm: ["TABBY"], currencyCode: "AED", value: 999)
        XCTAssertTrue(order.isBelowBnplMinimum(for: .tabby))
    }

    func testInitArgsUseTheAdvertisedLink() throws {
        let args = try bnplOrder(apm: ["TAMARA"]).toBnplInitArgs(for: .tamara)

        XCTAssertEqual(args.provider, .tamara)
        XCTAssertEqual(args.checkoutLink, "https://api.sandbox.ngenius-payments.com/payments/pay123/tamara")
        XCTAssertEqual(args.acceptLink, "https://api.sandbox.ngenius-payments.com/payments/pay123/tamara/accept")
        XCTAssertEqual(args.orderLink, "https://api.sandbox.ngenius-payments.com/orders/abc123")
    }

    /// An outlet that lists the APM without the rel still gets the option, with the endpoint
    /// derived from the payment's own self link.
    func testEndpointIsDerivedWhenTheRelIsAbsent() throws {
        let order = try bnplOrder(apm: ["TABBY"], rels: [])
        XCTAssertEqual(order.supportedBnplProviders, [.tabby])
        XCTAssertEqual(try order.toBnplInitArgs(for: .tabby).checkoutLink,
                       "https://api.sandbox.ngenius-payments.com/payments/pay123/tabby")
    }

    /// The return URLs are the paypage address the web checkout uses, with a marker the WebView
    /// matches on. The providers append their own parameters, so the marker has to survive that.
    func testReturnUrlsCarryTheAuthCodeAndTheResultMarker() throws {
        let args = try bnplOrder(apm: ["TABBY"]).toBnplInitArgs(for: .tabby)

        XCTAssertEqual(args.successUrl,
                       "https://paypage.sandbox.ngenius-payments.com/v2?code=AUTHCODE123&payment_method=tabby&ni_sdk_result=success")
        XCTAssertEqual(args.cancelUrl,
                       "https://paypage.sandbox.ngenius-payments.com/v2?code=AUTHCODE123&ni_sdk_result=cancel")
        XCTAssertEqual(args.failureUrl,
                       "https://paypage.sandbox.ngenius-payments.com/v2?code=AUTHCODE123&payment_method=tabby&ni_sdk_result=failure")
    }

    func testInitArgsThrowWhenTheAuthCodeIsMissing() throws {
        var links = TestFixtures.defaultPaymentLinks()
        links["payment:tamara"] = ["href": "https://api.example.com/payments/pay123/tamara"]
        let order = try TestFixtures.order(
            payPageHref: "https://paypage.sandbox.ngenius-payments.com/",
            paymentLinks: links,
            overrides: ["paymentMethods": ["apm": ["TAMARA"]]])

        XCTAssertThrowsError(try order.toBnplInitArgs(for: .tamara))
    }

    func testCheckoutTypeIsTheOnlyValueTheApmEndpointAccepts() {
        XCTAssertEqual(BnplInitArgs.checkoutType, "INSTALLMENTS")
    }

    /// The gateway named these itself and they do not follow one convention, so a swap between them
    /// would fail every accept call.
    func testEachProviderKeepsItsOwnAcceptFieldName() {
        XCTAssertEqual(BnplProvider.tamara.acceptIdField, "tamaraOrderId")
        XCTAssertEqual(BnplProvider.tabby.acceptIdField, "tabbyPaymentId")
    }

    /// Row tags survive the round trip, and a default-tagged view is not mistaken for a provider.
    func testRowTagsRoundTripAndRejectUntaggedViews() {
        for provider in BnplProvider.allCases {
            XCTAssertEqual(BnplProvider(rowTag: provider.rowTag), provider)
        }
        XCTAssertNil(BnplProvider(rowTag: 0))
    }
}

final class BnplInitResponseTests: XCTestCase {

    /// Verbatim from the gateway on the DEV outlet with Tamara live.
    func testDecodesTheLiveTamaraResponse() throws {
        let response = try TestFixtures.decode(BnplInitResponse.self, from: [
            "webUrl": "https://checkout-sandbox.tamara.co/checkout/ee26f7e6?orderId=761d053b",
            "tamaraOrderId": "761d053b-8bf4-4767-8bfb-0bcd2af004d8"
        ])

        XCTAssertEqual(response.checkoutUrl, "https://checkout-sandbox.tamara.co/checkout/ee26f7e6?orderId=761d053b")
        XCTAssertEqual(response.providerReference, "761d053b-8bf4-4767-8bfb-0bcd2af004d8")
    }

    func testReadsTabbysPaymentId() throws {
        let response = try TestFixtures.decode(BnplInitResponse.self,
                                               from: ["webUrl": "https://checkout.tabby.ai/abc",
                                                      "tabbyPaymentId": "tabby-1"])
        XCTAssertEqual(response.providerReference, "tabby-1")
    }

    /// The sibling APMs each spell the URL field differently, so every spelling is accepted rather
    /// than leaving the payer on a blank sheet if this one follows Benefit or QPay instead.
    func testAcceptsTheOtherSpellingsTheApmResponsesUse() throws {
        for field in ["redirectUrl", "paymentUrl", "checkoutUrl"] {
            let response = try TestFixtures.decode(BnplInitResponse.self,
                                                   from: [field: "https://checkout.tamara.co/abc"])
            XCTAssertEqual(response.checkoutUrl, "https://checkout.tamara.co/abc", "\(field) must be read")
        }
    }

    func testEmptyUrlsAreIgnoredInFavourOfAPopulatedOne() throws {
        let response = try TestFixtures.decode(BnplInitResponse.self,
                                               from: ["webUrl": "", "paymentUrl": "https://checkout.tamara.co/abc"])
        XCTAssertEqual(response.checkoutUrl, "https://checkout.tamara.co/abc")
    }

    func testCancelledAndErrorMessageAreRead() throws {
        let response = try TestFixtures.decode(BnplInitResponse.self,
                                               from: ["cancelled": true, "errorMessage": "order amount too low"])
        XCTAssertEqual(response.cancelled, true)
        XCTAssertEqual(response.errorMessage, "order amount too low")
        XCTAssertNil(response.checkoutUrl)
    }

    /// An order id and a payment id are different things, so the provider-specific name wins over
    /// the generic one rather than whichever the decoder happened to read first.
    func testProviderSpecificReferenceWinsOverTheGenericOne() throws {
        let response = try TestFixtures.decode(BnplInitResponse.self,
                                               from: ["tamaraOrderId": "tam-1", "orderId": "generic-1"])
        XCTAssertEqual(response.providerReference, "tam-1")
    }
}
