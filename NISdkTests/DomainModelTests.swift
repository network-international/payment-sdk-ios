//
//  DomainModelTests.swift
//  NISdkTests
//
//  Codable round-trips and the small value types the SDK hands back to merchants.
//

import XCTest
@testable import NISdk

final class SliceModelTests: XCTestCase {

    func testDecodesAnEligibilityResponse() throws {
        let response: SliceEligibilityResponse = try TestFixtures.decode(
            SliceEligibilityResponse.self,
            from: [
                "transactionAmount": ["currencyCode": "AED", "value": 50000],
                "indicator": "Y",
                "offers": [
                    ["period": "3", "rate": "0.00", "fee": "0", "feeType": "FIXED",
                     "installmentAmount": ["currencyCode": "AED", "value": 16667],
                     "totalAmount": ["currencyCode": "AED", "value": 50000]],
                    ["period": "6", "rate": "1.50", "fee": "500", "feeType": "FIXED",
                     "installmentAmount": ["currencyCode": "AED", "value": 8417],
                     "totalAmount": ["currencyCode": "AED", "value": 50500]]
                ]
            ])

        XCTAssertEqual(response.transactionAmount.value, 50000)
        XCTAssertEqual(response.indicator, "Y")
        XCTAssertEqual(response.offers.count, 2)
        XCTAssertEqual(response.offers[1].period, "6")
        XCTAssertEqual(response.offers[1].totalAmount.value, 50500)
    }

    func testIndicatorIsOptionalSoOlderBackendsStillDecode() throws {
        let response: SliceEligibilityResponse = try TestFixtures.decode(
            SliceEligibilityResponse.self,
            from: ["transactionAmount": ["currencyCode": "AED", "value": 100], "offers": []])

        XCTAssertNil(response.indicator)
        XCTAssertTrue(response.offers.isEmpty)
    }

    func testManualEntryRequestCarriesThePANAndNoToken() throws {
        let request = SliceEligibilityRequest(pan: "4111111111111111", expiry: "2030-12")
        let json = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(request)) as? [String: Any]

        XCTAssertEqual(json?["pan"] as? String, "4111111111111111")
        XCTAssertEqual(json?["expiry"] as? String, "2030-12")
        XCTAssertNil(json?["cardToken"])
    }

    func testSavedCardRequestCarriesTheTokenAndNoPAN() throws {
        let request = SliceEligibilityRequest(cardToken: "tok-abc", expiry: "2030-12")
        let json = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(request)) as? [String: Any]

        XCTAssertEqual(json?["cardToken"] as? String, "tok-abc")
        XCTAssertNil(json?["pan"])
    }

    func testSliceRequestRoundTrips() throws {
        let request = SliceRequest(period: "6", rate: "1.50", fee: "500")
        let decoded = try JSONDecoder().decode(SliceRequest.self, from: try JSONEncoder().encode(request))

        XCTAssertEqual(decoded.period, "6")
        XCTAssertEqual(decoded.rate, "1.50")
        XCTAssertEqual(decoded.fee, "500")
    }
}

final class AaniPayRequestTests: XCTestCase {

    func testEncodesTheAliasFieldsTheGatewayExpects() throws {
        let request = AaniPayRequest(aliasType: "MOBILE_NUMBER",
                                     payerIp: "10.0.0.1",
                                     backLink: "https://merchant.example.com/return")
        request.mobileNumber = MobileNumber(countryCode: "971", number: "500000000")

        let json = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(request)) as? [String: Any]

        XCTAssertEqual(json?["aliasType"] as? String, "MOBILE_NUMBER")
        XCTAssertEqual(json?["payerIp"] as? String, "10.0.0.1")
        XCTAssertEqual(json?["backLink"] as? String, "https://merchant.example.com/return")
        XCTAssertEqual(json?["source"] as? String, "MOBILE_APP", "the SDK always identifies itself as MOBILE_APP")

        let mobile = json?["mobileNumber"] as? [String: Any]
        XCTAssertEqual(mobile?["countryCode"] as? String, "971")
        XCTAssertEqual(mobile?["number"] as? String, "500000000")
    }

    func testUnsetAliasesAreNotOmittedButNull() throws {
        let request = AaniPayRequest(aliasType: "EMIRATES_ID", payerIp: "10.0.0.1", backLink: "back")
        request.emiratesId = "784-1234-1234567-1"

        let json = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(request)) as? [String: Any]

        XCTAssertEqual(json?["emiratesId"] as? String, "784-1234-1234567-1")
        XCTAssertTrue(json?["passportId"] is NSNull)
        XCTAssertTrue(json?["emailId"] is NSNull)
    }

    func testRoundTripsThroughDecoding() throws {
        let request = AaniPayRequest(aliasType: "EMAIL", payerIp: "10.0.0.1", backLink: "back")
        request.emailId = "payer@example.com"

        let decoded = try JSONDecoder().decode(AaniPayRequest.self, from: try JSONEncoder().encode(request))

        XCTAssertEqual(decoded.aliasType, "EMAIL")
        XCTAssertEqual(decoded.emailId, "payer@example.com")
        XCTAssertNil(decoded.mobileNumber)
    }
}

final class NIPaymentErrorTests: XCTestCase {

    func testEveryCategoryHasAStableWireName() {
        let expected: [(NIPaymentErrorCategory, String)] = [
            (.network, "network"),
            (.configuration, "configuration"),
            (.declined, "declined"),
            (.timeout, "timeout"),
            (.provider, "provider"),
            (.unknown, "unknown")
        ]
        for (category, name) in expected {
            XCTAssertEqual(category.rawVal, name)
        }
    }

    func testCategoryRoundTripsThroughItsWireName() {
        for category in [NIPaymentErrorCategory.network, .configuration, .declined, .timeout, .provider, .unknown] {
            XCTAssertEqual(NIPaymentErrorCategory(rawVal: category.rawVal), category)
        }
    }

    func testAnUnrecognisedNameFallsBackToUnknown() {
        XCTAssertEqual(NIPaymentErrorCategory(rawVal: "something-new"), .unknown)
        XCTAssertEqual(NIPaymentErrorCategory(rawVal: ""), .unknown)
    }

    func testCarriesMessageAndPaymentMethod() {
        let error = NIPaymentError(category: .declined, message: "Insufficient funds", paymentMethod: "BENEFIT")

        XCTAssertEqual(error.category, .declined)
        XCTAssertEqual(error.message, "Insufficient funds")
        XCTAssertEqual(error.paymentMethod, "BENEFIT")
    }

    func testPaymentMethodIsOptional() {
        let error = NIPaymentError(category: .network, message: nil)

        XCTAssertNil(error.message)
        XCTAssertNil(error.paymentMethod)
    }

    func testDescriptionIsUsableInALogLine() {
        let error = NIPaymentError(category: .timeout, message: "took too long", paymentMethod: "QPAY")
        XCTAssertEqual(error.description, "NIPaymentError(category: timeout, method: QPAY, message: took too long)")

        let sparse = NIPaymentError(category: .unknown, message: nil)
        XCTAssertEqual(sparse.description, "NIPaymentError(category: unknown, method: -, message: -)")
    }
}

final class PaymentEnumTests: XCTestCase {

    func testPaymentStatusNamesMatchTheDocumentedContract() {
        XCTAssertEqual(PaymentStatus.PaymentSuccess.rawVal, "PaymentSuccess")
        XCTAssertEqual(PaymentStatus.PaymentFailed.rawVal, "PaymentFailed")
        XCTAssertEqual(PaymentStatus.PaymentCancelled.rawVal, "PaymentCancelled")
        XCTAssertEqual(PaymentStatus.InValidRequest.rawVal, "InValidRequest")
        XCTAssertEqual(PaymentStatus.PaymentPostAuthReview.rawVal, "PaymentPostAuthReview")
    }

    func testPartialAuthStatusesUseTheGatewaysScreamingSnakeCase() {
        XCTAssertEqual(PaymentStatus.PartialAuthDeclined.rawVal, "PARTIAL_AUTH_DECLINED")
        XCTAssertEqual(PaymentStatus.PartialAuthDeclineFailed.rawVal, "PARTIAL_AUTH_DECLINE_FAILED")
        XCTAssertEqual(PaymentStatus.PartiallyAuthorised.rawVal, "PARTIALLY_AUTHORISED")
    }

    func testPaymentStatusRoundTrips() {
        let all: [PaymentStatus] = [.PaymentSuccess, .PaymentFailed, .PaymentCancelled, .InValidRequest,
                                    .PaymentPostAuthReview, .PartialAuthDeclined,
                                    .PartialAuthDeclineFailed, .PartiallyAuthorised]
        for status in all {
            XCTAssertEqual(PaymentStatus(rawVal: status.rawVal), status)
        }
    }

    func testAnUnknownStatusIsTreatedAsCancelledRatherThanSucceeded() {
        XCTAssertEqual(PaymentStatus(rawVal: "SOMETHING_ELSE"), .PaymentCancelled)
    }

    func testPaymentMediumNames() {
        XCTAssertEqual(PaymentMedium.ApplePay.rawVal, "ApplePay")
        XCTAssertEqual(PaymentMedium.Card.rawVal, "Card")
        XCTAssertEqual(PaymentMedium.ThreeDSTwo.rawVal, "ThreeDSTwo")
        XCTAssertEqual(PaymentMedium.SavedCard.rawVal, "SavedCard")
    }

    func testPaymentMediumFallsBackToCard() {
        XCTAssertEqual(PaymentMedium(rawVal: "ApplePay"), .ApplePay)
        XCTAssertEqual(PaymentMedium(rawVal: "SomethingElse"), .Card)
        XCTAssertEqual(PaymentMedium(rawVal: "SavedCard"), .Card,
                       "documents that SavedCard has no init? branch and falls through to Card")
    }
}

final class CardProviderTests: XCTestCase {

    func testGatewayRoutingSchemesAreNotApplePayNetworks() {
        XCTAssertFalse(CardProvider.qpay.isApplePayNetwork)
        XCTAssertFalse(CardProvider.benefit.isApplePayNetwork)
    }

    func testRealCardNetworksAreApplePayNetworks() {
        for provider in [CardProvider.visa, .masterCard, .americanExpress, .discover, .jcb, .mada] {
            XCTAssertTrue(provider.isApplePayNetwork, "\(provider) should be offered to Apple Pay")
        }
    }

    func testWireNamesMatchTheGateway() {
        XCTAssertEqual(CardProvider.masterCard.rawValue, "MASTERCARD")
        XCTAssertEqual(CardProvider.dinersClubInternational.rawValue, "DINERS_CLUB_INTERNATIONAL")
        XCTAssertEqual(CardProvider.americanExpress.rawValue, "AMERICAN_EXPRESS")
        XCTAssertEqual(CardProvider.benefit.rawValue, "BENEFIT")
        XCTAssertEqual(CardProvider.qpay.rawValue, "QPAY")
    }
}

final class AmountTests: XCTestCase {

    func testFormattedValueConvertsMinorUnitsToMajor() {
        XCTAssertEqual(Amount(currencyCode: "AED", value: 5000).getFormattedAmountValue(), "50.00")
        XCTAssertEqual(Amount(currencyCode: "AED", value: 5).getFormattedAmountValue(), "0.05")
        XCTAssertEqual(Amount(currencyCode: "AED", value: 0).getFormattedAmountValue(), "0.00")
    }

    func testFormattedAmountIsPrefixedWithTheCurrencyCode() {
        XCTAssertEqual(Amount(currencyCode: "AED", value: 5000).getFormattedAmount(), "AED 50.00")
    }

    func testThreeDecimalCurrenciesUseThreeMinorDigits() {
        // BHD has 3 minor units, so 5000 fils is 5.000 dinars — rendered to 2 decimals as 5.00.
        XCTAssertEqual(Amount(currencyCode: "BHD", value: 5000).getFormattedAmountValue(), "5.00")
    }

    func testAMissingValueFormatsAsEmpty() {
        XCTAssertEqual(Amount(currencyCode: "AED", value: nil).getFormattedAmountValue(), "")
        XCTAssertEqual(Amount(currencyCode: "AED", value: nil).getFormattedAmount(), "AED ")
    }

    func testDecodesFromTheGatewayShape() throws {
        let amount: Amount = try TestFixtures.decode(Amount.self, from: ["currencyCode": "AED", "value": 12345])
        XCTAssertEqual(amount.currencyCode, "AED")
        XCTAssertEqual(amount.value, 12345)
    }
}
