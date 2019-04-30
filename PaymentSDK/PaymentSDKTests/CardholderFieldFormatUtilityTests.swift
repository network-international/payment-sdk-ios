import XCTest
@testable import PaymentSDK

class CardholderFieldFormatUtilityTests : XCTestCase
{
    func test_preview_00()
    {
        let preview = CardholderFieldFormatUtility.preview(forText: "")
        XCTAssert( preview == LocalizedString("cardholder_field_preview", comment: ""),
                   "The preview string should be the localized CARDHOLDER NAME.")
    }
    
    func test_preview_01()
    {
        let preview = CardholderFieldFormatUtility.preview(forText: "A")
        XCTAssert( preview == "",
                   "The preview string should be empty.")
    }
    
    func test_validText_00()
    {
        let text = CardholderFieldFormatUtility.validTextOnly(forText: "12@$6A bEe8/][")
        XCTAssert( text == "A BEE",
                   "The valid text string should be 'A BEE'.")
    }
    
    func test_validText_01()
    {
        let text = CardholderFieldFormatUtility.validTextOnly(forText: "abcdefghijklmnopqrstuvwxyz .-'")
        XCTAssert( text == "ABCDEFGHIJKLMNOPQRSTUVWXYZ .-'",
                   "The valid text string should be 'ABCDEFGHIJKLMNOPQRSTUVWXYZ .-''.")
    }
}
