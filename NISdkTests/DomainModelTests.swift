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

    // MARK: - Installment fee (the offer's `commission`)

    private func offer(commission: Any?, fee: String = "0") throws -> SliceOffer {
        var json: [String: Any] = [
            "period": "3", "rate": "0.00", "fee": fee, "feeType": "FIXED",
            "installmentAmount": ["currencyCode": "AED", "value": 20733],
            "totalAmount": ["currencyCode": "AED", "value": 62200]
        ]
        if let commission = commission { json["commission"] = commission }
        return try TestFixtures.decode(SliceOffer.self, from: json)
    }

    /// The value behind the "Installment fees" row: the planned commission the backend quotes for
    /// the selected plan, in major units.
    func testAPositiveCommissionIsTheInstallmentFee() throws {
        XCTAssertEqual(try offer(commission: "7.00").installmentFeeAmount, 7.00)
    }

    /// The row is hidden on a zero fee, so the parsed value must be nil rather than 0 — the view
    /// decides purely on nil-ness.
    func testAZeroCommissionCarriesNoInstallmentFee() throws {
        XCTAssertNil(try offer(commission: "0").installmentFeeAmount)
        XCTAssertNil(try offer(commission: "0.00").installmentFeeAmount)
    }

    func testAnAbsentCommissionCarriesNoInstallmentFee() throws {
        XCTAssertNil(try offer(commission: nil).installmentFeeAmount)
    }

    /// A plan the backend quotes without a usable number must hide the row rather than render
    /// something meaningless next to an amount the payer is about to be charged.
    func testAnUnparsableCommissionCarriesNoInstallmentFee() throws {
        XCTAssertNil(try offer(commission: "").installmentFeeAmount)
        XCTAssertNil(try offer(commission: "n/a").installmentFeeAmount)
        XCTAssertNil(try offer(commission: "-7.00").installmentFeeAmount)
    }

    /// The breakdown's "Total after N months" reads the backend total directly, which the design
    /// has covering the order amount plus the installment fee (615.00 + 7.00).
    func testTheOfferCarriesTheBackendTotal() throws {
        XCTAssertEqual(try offer(commission: "7.00").totalAmount.value, 62200)
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

    // MARK: - "Zero fees" tag

    /// The tag needs both charges to be zero — processing fee and installment fee.
    func testZeroFeeAndNoCommissionIsFeeFree() throws {
        XCTAssertTrue(try offer(commission: nil).isFeeFree)
        XCTAssertTrue(try offer(commission: "0").isFeeFree)
        XCTAssertTrue(try offer(commission: "0.00", fee: "0.00").isFeeFree)
    }

    func testAnInstallmentFeeAloneRulesOutTheZeroFeesTag() throws {
        XCTAssertFalse(try offer(commission: "18.00").isFeeFree)
    }

    func testAProcessingFeeAloneRulesOutTheZeroFeesTag() throws {
        XCTAssertFalse(try offer(commission: nil, fee: "8.00").isFeeFree)
        XCTAssertFalse(try offer(commission: "0", fee: "8").isFeeFree)
    }

    func testAnUnparsableProcessingFeeIsNotShownAsZero() throws {
        XCTAssertFalse(try offer(commission: nil, fee: "").isFeeFree)
    }
}

/// The receipt restates the plan the payer agreed to on the offer card, and the card builds its
/// figures through `SliceReceipt.from` — so these pin what both screens show.
final class SliceReceiptTests: XCTestCase {

    private func offer(period: String = "4", rate: String = "0.00", fee: String = "0",
                       feeType: String = "F", commission: String? = nil) throws -> SliceOffer {
        var json: [String: Any] = [
            "period": period, "rate": rate, "fee": fee, "feeType": feeType,
            "installmentAmount": ["currencyCode": "AED", "value": 271950],
            "totalAmount": ["currencyCode": "AED", "value": 1087800]
        ]
        if let commission = commission { json["commission"] = commission }
        return try TestFixtures.decode(SliceOffer.self, from: json)
    }

    func testCarriesThePeriodAsSentSoTheViewCanPluraliseIt() throws {
        XCTAssertEqual(SliceReceipt.from(offer: try offer(period: "4"), isIslamic: false).period, "4")
    }

    func testFormatsTheInstallmentAmountWithGroupingAndTwoDecimals() throws {
        XCTAssertEqual(SliceReceipt.from(offer: try offer(), isIslamic: false).installmentAmount, "AED 2,719.50")
    }

    func testShowsTheRateAsAPercentage() throws {
        XCTAssertEqual(SliceReceipt.from(offer: try offer(rate: "1.5"), isIslamic: false).rate, "1.5%")
    }

    func testAPercentageFeeTypeIsShownAsAPercentageNotAnAmount() throws {
        XCTAssertEqual(SliceReceipt.from(offer: try offer(fee: "2", feeType: "P"), isIslamic: false).processingFees, "2%")
    }

    func testAFixedFeeIsShownAsAnAmountInTheOfferCurrency() throws {
        XCTAssertEqual(SliceReceipt.from(offer: try offer(fee: "25"), isIslamic: false).processingFees, "AED 25.00")
    }

    /// `0.29 * 100` is `28.999…`; truncating it quoted the payer AED 0.28.
    func testAFixedFeeIsRoundedToTheNearestMinorUnitNotTruncated() throws {
        XCTAssertEqual(SliceReceipt.from(offer: try offer(fee: "0.29"), isIslamic: false).processingFees, "AED 0.29")
    }

    func testAnUnparsableFixedFeeIsShownAsZero() throws {
        XCTAssertEqual(SliceReceipt.from(offer: try offer(fee: ""), isIslamic: false).processingFees, "AED 0.00")
    }

    func testACommissionBecomesTheInstallmentFeeRow() throws {
        XCTAssertEqual(SliceReceipt.from(offer: try offer(commission: "7.00"), isIslamic: false).installmentFees, "AED 7.00")
    }

    func testTheInstallmentFeeIsRoundedNotTruncated() throws {
        XCTAssertEqual(SliceReceipt.from(offer: try offer(commission: "0.29"), isIslamic: false).installmentFees, "AED 0.29")
    }

    /// The view hides the row purely on nil-ness, as the offer card does.
    func testNoCommissionMeansNoInstallmentFeeRow() throws {
        XCTAssertNil(SliceReceipt.from(offer: try offer(commission: nil), isIslamic: false).installmentFees)
        XCTAssertNil(SliceReceipt.from(offer: try offer(commission: "0.00"), isIslamic: false).installmentFees)
    }

    func testCarriesTheIslamicFlagThatPicksTheProfitRateLabel() throws {
        XCTAssertTrue(SliceReceipt.from(offer: try offer(), isIslamic: true).isIslamic)
        XCTAssertFalse(SliceReceipt.from(offer: try offer(), isIslamic: false).isIslamic)
    }

    /// Grouping must not depend on the device locale: an Arabic or French device would otherwise
    /// change the separators between the card and the receipt.
    func testLargeAmountsGroupThousandsWithCommas() {
        XCTAssertEqual(SliceReceipt.formatAmount(minorUnits: 123456789, currency: "AED"), "AED 1,234,567.89")
    }

    func testANonNumericPeriodIsShownAsSent() {
        XCTAssertEqual(SliceCopy.months("slice_tab_months", period: "flex"), "flex")
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
