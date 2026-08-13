//
//  PaymentFieldTests.swift
//  NISdkTests
//
//  The card-entry field models: scheme detection, validation, and the
//  NotificationCenter traffic the card form listens to.
//

import XCTest
@testable import NISdk

final class PanTests: XCTestCase {

    private func pan(_ value: String) -> Pan {
        let pan = Pan()
        pan.value = value
        return pan
    }

    func testDetectsEachSupportedScheme() {
        let cases: [(String, CardProvider)] = [
            ("4111111111111111", .visa),
            ("4242424242424242", .visa),
            ("5555555555554444", .masterCard),
            ("378282246310005", .americanExpress),
            ("371449635398431", .americanExpress),
            ("6011111111111117", .discover),
            ("30569309025904", .dinersClubInternational),   // Diners is 14 digits
            ("3530111333300000", .jcb),
            ("4464040000000000", .mada)
        ]
        for (number, expected) in cases {
            XCTAssertEqual(pan(number).cardProvider, expected, "wrong scheme for \(number)")
        }
    }

    func testUnrecognisedPrefixIsUnknown() {
        XCTAssertEqual(pan("9999999999999999").cardProvider, .unknown)
        XCTAssertEqual(Pan().cardProvider, .unknown, "an empty field has no scheme")
    }

    func testSchemesWithoutAPatternAreNeverMatched() {
        // JAYWAN, QPAY and BENEFIT have no regex; they must not swallow every card number.
        for number in ["4111111111111111", "5555555555554444", "378282246310005"] {
            let provider = pan(number).cardProvider
            XCTAssertFalse([.jaywan, .qpay, .benefit].contains(provider),
                           "\(number) was misdetected as \(provider)")
        }
    }

    func testValidateDelegatesToLuhn() {
        XCTAssertTrue(pan("4111111111111111").validate())
        XCTAssertFalse(pan("4111111111111112").validate())
        XCTAssertFalse(Pan().validate(), "a nil value is not valid")
    }

    func testValidateDoesNotStripFormattingSpaces() {
        // Documents that callers must pass the trimmed value; the form does this before validating.
        XCTAssertFalse(pan("4111 1111 1111 1111").validate())
    }

    func testTrimmedValueRemovesGroupingSpaces() {
        XCTAssertEqual(pan("4111 1111 1111 1111").trimmedValue, "4111111111111111")
        XCTAssertNil(Pan().trimmedValue)
    }

    func testHasValidLengthCoversThe13To19DigitRange() {
        XCTAssertTrue(pan("4111111111111").hasValidLength())          // 13
        XCTAssertTrue(pan("4111111111111111").hasValidLength())       // 16
        XCTAssertTrue(pan("4111111111111111111").hasValidLength())    // 19
        XCTAssertFalse(pan("411111111111").hasValidLength())          // 12
        XCTAssertFalse(pan("41111111111111111111").hasValidLength())  // 20
        XCTAssertFalse(pan("").hasValidLength())
        XCTAssertFalse(Pan().hasValidLength())
    }

    func testHasValidLengthCountsDigitsNotSpaces() {
        XCTAssertTrue(pan("4111 1111 1111 1111").hasValidLength())
    }

    func testSettingTheValuePostsAPanChangeNotification() {
        let field = Pan()
        expectation(forNotification: .didChangePan, object: field) { notification in
            let info = notification.userInfo
            XCTAssertEqual(info?["value"] as? String, "4111111111111111")
            XCTAssertEqual(info?["isValid"] as? Bool, true)
            XCTAssertEqual(info?["cardProvider"] as? CardProvider, .visa)
            return true
        }
        field.value = "4111111111111111"
        waitForExpectations(timeout: 1)
    }
}

final class CvvTests: XCTestCase {

    func testDefaultsToThreeDigits() {
        let cvv = Cvv()
        XCTAssertEqual(cvv.length, CVVLengths.normal)
        cvv.value = "123"
        XCTAssertTrue(cvv.validate())
        cvv.value = "1234"
        XCTAssertFalse(cvv.validate())
    }

    func testNilValueIsInvalid() {
        XCTAssertFalse(Cvv().validate())
    }

    func testAmexPanWidensTheFieldToFourDigits() {
        let cvv = Cvv()
        let pan = Pan()
        pan.value = "378282246310005"   // posts .didChangePan, which Cvv observes

        XCTAssertEqual(cvv.length, CVVLengths.amex)
        cvv.value = "1234"
        XCTAssertTrue(cvv.validate())
        cvv.value = "123"
        XCTAssertFalse(cvv.validate())
    }

    func testSwitchingBackToANonAmexPanNarrowsTheFieldAgain() {
        let cvv = Cvv()
        let pan = Pan()
        pan.value = "378282246310005"
        XCTAssertEqual(cvv.length, CVVLengths.amex)

        pan.value = "4111111111111111"
        XCTAssertEqual(cvv.length, CVVLengths.normal)
    }

    func testSettingTheValuePostsACvvChangeNotification() {
        let cvv = Cvv()
        expectation(forNotification: .didChangeCVV, object: cvv) { notification in
            XCTAssertEqual(notification.userInfo?["value"] as? String, "123")
            XCTAssertEqual(notification.userInfo?["isValid"] as? Bool, true)
            return true
        }
        cvv.value = "123"
        waitForExpectations(timeout: 1)
    }
}

final class ExpiryDateTests: XCTestCase {

    private func expiry(month: String?, year: String?) -> ExpiryDate {
        let date = ExpiryDate()
        date.month = month
        date.year = year
        return date
    }

    /// Two-digit year comfortably in the future, so the test does not rot.
    private var futureYear: String {
        let year = Calendar.current.component(.year, from: Date()) + 5
        return String(year % 100)
    }

    private var pastYear: String {
        let year = Calendar.current.component(.year, from: Date()) - 5
        return String(format: "%02d", year % 100)
    }

    func testAFutureDateIsValid() {
        XCTAssertTrue(expiry(month: "12", year: futureYear).validate())
    }

    func testAPastDateIsRejected() {
        XCTAssertFalse(expiry(month: "01", year: pastYear).validate())
    }

    func testIncompleteInputIsRejected() {
        XCTAssertFalse(expiry(month: "12", year: nil).validate())
        XCTAssertFalse(expiry(month: nil, year: futureYear).validate())
        XCTAssertFalse(ExpiryDate().validate())
    }

    func testAnImpossibleMonthIsRejected() {
        XCTAssertFalse(expiry(month: "13", year: futureYear).validate())
        XCTAssertFalse(expiry(month: "00", year: futureYear).validate())
        XCTAssertFalse(expiry(month: "ab", year: futureYear).validate())
    }

    func testChangingEitherComponentPostsANotification() {
        let date = ExpiryDate()
        let year = futureYear
        expectation(forNotification: .didChangeExpiryDate, object: date) { notification in
            guard notification.userInfo?["year"] as? String == year else { return false }
            XCTAssertEqual(notification.userInfo?["month"] as? String, "12")
            XCTAssertEqual(notification.userInfo?["isValid"] as? Bool, true)
            return true
        }
        date.month = "12"
        date.year = year
        waitForExpectations(timeout: 1)
    }
}

final class CardHolderNameTests: XCTestCase {

    private func name(_ value: String?) -> CardHolderName {
        let holder = CardHolderName()
        holder.value = value
        return holder
    }

    func testAcceptsOrdinaryNames() {
        XCTAssertTrue(name("John Smith").validate())
        XCTAssertTrue(name("O'Brien-Smith").validate())
        XCTAssertTrue(name("محمد").validate())
    }

    func testRejectsNamesContainingDigits() {
        XCTAssertFalse(name("John Smith 2").validate())
        XCTAssertFalse(name("1234").validate())
    }

    func testRejectsEmptyAndUnset() {
        XCTAssertFalse(name("").validate())
        XCTAssertFalse(CardHolderName().validate())
    }

    func testSettingTheValuePostsANameChangeNotification() {
        let holder = CardHolderName()
        expectation(forNotification: .didChangeCardHolderName, object: holder) { notification in
            XCTAssertEqual(notification.userInfo?["value"] as? String, "John Smith")
            XCTAssertEqual(notification.userInfo?["isValid"] as? Bool, true)
            return true
        }
        holder.value = "John Smith"
        waitForExpectations(timeout: 1)
    }
}
