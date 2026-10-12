//
//  BenefitTests.swift
//  NISdkTests
//
//  Starting a Benefit payment: reading why the gateway refused, and deciding which outcomes
//  end the payment rather than handing the payer back to the payment page.
//

import XCTest
@testable import NISdk

final class BenefitInitErrorBodyTests: XCTestCase {

    private func body(_ json: [String: Any]) throws -> BenefitInitErrorBody {
        return try TestFixtures.decode(BenefitInitErrorBody.self, from: json)
    }

    /// Verbatim from a sandbox outlet that lists BENEFIT but has no BENEFIT keys provisioned. This
    /// is the shape the SDK has to read: `BenefitInitResponse` decodes it to all-nils, so without
    /// the envelope the payer's log says only "status unknown".
    func testReadsTheReasonAnOutletWithoutBenefitKeysIsRefusedWith() throws {
        let decoded = try body([
            "message": "Unprocessable Entity",
            "errors": [[
                "message": "Failed to encrypt BENEFIT trandata",
                "localizedMessage": "{error.processing.invalidBenefitPayment}",
                "errorCode": "invalidBenefitPayment",
                "domain": "processing"
            ]],
            "code": 422
        ])

        XCTAssertEqual(decoded.reason, "Failed to encrypt BENEFIT trandata (invalidBenefitPayment)")
    }

    func testFallsBackToTheEnvelopeMessageWhenNoDetailIsCarried() throws {
        let decoded = try body(["message": "Unprocessable Entity", "code": 422])

        XCTAssertEqual(decoded.reason, "Unprocessable Entity")
    }

    func testDetailWithoutAnErrorCodeIsReportedOnItsOwn() throws {
        let decoded = try body([
            "message": "Unprocessable Entity",
            "errors": [["message": "Benefit is not enabled for this outlet"]]
        ])

        XCTAssertEqual(decoded.reason, "Benefit is not enabled for this outlet")
    }

    /// A body that is not an error envelope must not produce a misleading reason — the caller falls
    /// back to logging it verbatim instead.
    func testCarriesNoReasonWhenTheBodyIsNotAnErrorEnvelope() throws {
        let decoded = try body(["paymentUrl": "https://benefit.example.com/pay"])

        XCTAssertNil(decoded.reason)
    }

    func testEmptyMessagesAreTreatedAsAbsent() throws {
        let decoded = try body(["message": "", "errors": [["message": ""]]])

        XCTAssertNil(decoded.reason)
    }
}

final class BenefitPaymentStatusRoutingTests: XCTestCase {

    private func error(_ category: NIPaymentErrorCategory) -> NIPaymentError {
        return NIPaymentError(category: category, message: "reason",
                              paymentMethod: BenefitViewController.methodName)
    }

    /// A refused initiation is the outlet's configuration, not a payment: the payer never reached
    /// Benefit and nothing was recorded, so their other methods must survive it.
    func testARefusedInitiationReturnsThePayerToThePaymentPage() {
        XCTAssertTrue(BenefitPaymentStatus.couldNotStart(error(.provider)).returnsToPaymentPage)
        XCTAssertTrue(BenefitPaymentStatus.couldNotStart(error(.configuration)).returnsToPaymentPage)
        XCTAssertTrue(BenefitPaymentStatus.couldNotStart(error(.network)).returnsToPaymentPage)
    }

    func testBackingOutReturnsThePayerToThePaymentPage() {
        XCTAssertTrue(BenefitPaymentStatus.dismissed.returnsToPaymentPage)
        XCTAssertTrue(BenefitPaymentStatus.cancelledOnProvider.returnsToPaymentPage)
    }

    /// Everything the payer actually authorised is a real outcome and ends the payment — including
    /// a poll timeout, which the merchant reconciles from the order rather than retries.
    func testRealOutcomesEndThePayment() {
        XCTAssertFalse(BenefitPaymentStatus.success.returnsToPaymentPage)
        XCTAssertFalse(BenefitPaymentStatus.postAuthReview.returnsToPaymentPage)
        XCTAssertFalse(BenefitPaymentStatus.failed(error(.timeout)).returnsToPaymentPage)
        XCTAssertFalse(BenefitPaymentStatus.failed(error(.provider)).returnsToPaymentPage)
    }
}
