//
//  TermsAgreementTests.swift
//  NISdkTests
//
//  The disclaimer under the Pay button: only the "terms and conditions" phrase is a link, and it
//  must carry a real `.link` attribute — that is what makes it tappable, on both this text and the
//  QPay express one.
//

import XCTest
@testable import NISdk

final class TermsAgreementTests: XCTestCase {

    private let url = URL(string: UnifiedPaymentPageViewController.termsAndConditionsUrl)!
    private let sentence = "By clicking \"Pay\", you agree to the terms and conditions and authorize this transaction."

    private func attributed(_ sentence: String, phrase: String = "Terms and Conditions") -> NSAttributedString {
        return UnifiedPaymentPageViewController.termsAgreementAttributedText(
            sentence: sentence, linkPhrase: phrase, url: url, alignment: .center)
    }

    /// The regression this file exists for: the phrase was underlined but carried no link, so
    /// nothing happened when a payer tapped it.
    func testThePhraseCarriesALinkToTheTermsPage() {
        let text = attributed(sentence)
        let phraseRange = (text.string as NSString).range(of: "terms and conditions", options: .caseInsensitive)

        var effective = NSRange()
        let link = text.attribute(.link, at: phraseRange.location, effectiveRange: &effective) as? URL

        XCTAssertEqual(link, url)
        XCTAssertEqual(effective, phraseRange, "the link must cover the phrase exactly")
    }

    func testThePhraseIsUnderlined() {
        let text = attributed(sentence)
        let phraseRange = (text.string as NSString).range(of: "terms and conditions", options: .caseInsensitive)

        let underline = text.attribute(.underlineStyle, at: phraseRange.location, effectiveRange: nil) as? Int
        XCTAssertEqual(underline, NSUnderlineStyle.single.rawValue)
    }

    /// Everything either side of the phrase is ordinary caption text — tapping it must do nothing.
    func testTheRestOfTheSentenceIsNotALink() {
        let text = attributed(sentence)

        XCTAssertNil(text.attribute(.link, at: 0, effectiveRange: nil))
        XCTAssertNil(text.attribute(.link, at: text.length - 1, effectiveRange: nil))
    }

    /// Arabic wording, matching the shipped `ar` disclaimer. The phrase is found by the localized
    /// term, not the English fallback.
    func testFindsTheLocalisedPhrase() {
        let arabic = "بالضغط على \"ادفع\"، فإنك توافق على الشروط والأحكام وتصرح بهذه المعاملة."
        let text = attributed(arabic, phrase: "الشروط والأحكام")
        let phraseRange = (arabic as NSString).range(of: "الشروط والأحكام")

        XCTAssertEqual(text.attribute(.link, at: phraseRange.location, effectiveRange: nil) as? URL, url)
    }

    /// A locale whose disclaimer was translated but whose phrase key was not still links the
    /// English wording if the sentence happens to carry it.
    func testFallsBackToTheUntranslatedPhrase() {
        let text = attributed(sentence, phrase: "Conditions générales")
        let phraseRange = (sentence as NSString).range(of: "terms and conditions", options: .caseInsensitive)

        XCTAssertEqual(text.attribute(.link, at: phraseRange.location, effectiveRange: nil) as? URL, url)
    }

    /// Wording that contains the phrase nowhere must not crash or link an arbitrary range.
    func testNoLinkWhenThePhraseIsAbsent() {
        let text = attributed("Payment disclaimer with no matching phrase.", phrase: "nope")

        text.enumerateAttribute(.link, in: NSRange(location: 0, length: text.length)) { value, _, _ in
            XCTAssertNil(value)
        }
    }

    func testTheAlignmentRequestedIsApplied() {
        let text = attributed(sentence)
        let style = text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle

        XCTAssertEqual(style?.alignment, .center)
    }
}
