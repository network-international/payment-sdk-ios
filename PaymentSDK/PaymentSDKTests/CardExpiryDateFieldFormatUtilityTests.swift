import XCTest
@testable import PaymentSDK

class CardExpiryDateFieldFormatUtilityTests: XCTestCase
{    
    // MARK: - Previw -
    
    func test_preview_00()
    {
        let preview = CardExpiryDateFieldFormatUtility.preview(forText: nil)
        XCTAssert(preview == PreviewDefault.endDate,
                  "The preview string should be MM/YY for a nil string.")
    }
    
    func test_preview_01()
    {
        let preview = CardExpiryDateFieldFormatUtility.preview(forText: "")
        XCTAssert(preview == PreviewDefault.endDate,
                  "The preview string should be MM/YY for an empty string.")
    }
    
    func test_preview_02()
    {
        let preview = CardExpiryDateFieldFormatUtility.preview(forText: "1")
        XCTAssert(preview == "1M/YY",
                  "The preview string should be 1M/YY.")
    }
    
    func test_preview_03()
    {
        let preview = CardExpiryDateFieldFormatUtility.preview(forText: "12")
        XCTAssert(preview == "12/YY",
                  "The preview string should be 12/YY.")
    }
    
    func test_preview_04()
    {
        let preview = CardExpiryDateFieldFormatUtility.preview(forText: "12/")
        XCTAssert(preview == "12/YY",
                  "The preview string should be 12/YY.")
    }
    
    func test_preview_05()
    {
        let preview = CardExpiryDateFieldFormatUtility.preview(forText: "12/3")
        XCTAssert(preview == "12/3Y",
                  "The preview string should be 12/3Y.")
    }
    
    func test_preview_06()
    {
        let preview = CardExpiryDateFieldFormatUtility.preview(forText: "12/33")
        XCTAssert(preview == "12/33",
                  "The preview string should be 12/33.")
    }
    
    // MARK: - Reformat digits -
    
    func test_reformat_00()
    {
        let reformatted = CardExpiryDateFieldFormatUtility.reformatInputField(forText: "1233")
        XCTAssert(reformatted == "12/33",
                  "The reformatted string should be 12/33.")
    }
    
    func test_reformat_01()
    {
        let reformatted = CardExpiryDateFieldFormatUtility.reformatInputField(forText: "12333")
        XCTAssert(reformatted == "12/333",
                  "The reformatted string should be 12/333.")
    }
    
    func test_reformat_02()
    {
        let reformatted = CardExpiryDateFieldFormatUtility.reformatInputField(forText: nil)
        XCTAssert(reformatted == nil,
                  "The reformatted string should be nil for a nil string.")
    }
    
    func test_reformat_03()
    {
        let reformatted = CardExpiryDateFieldFormatUtility.reformatInputField(forText: "")
        XCTAssert(reformatted == "",
                  "The reformatted string should be empty for an empty string.")
    }

}


