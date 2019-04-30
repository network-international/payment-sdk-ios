import XCTest
@testable import PaymentSDK

class CardNumberFormatUtilityTests: XCTestCase
{
    // MARK: - Digits only -
    
    func test_digits_00()
    {
        let digitsOnly = CardNumberFormatUtility.digitsOnly(forText:"12/45")
        XCTAssert(digitsOnly == "1245",
                  "The digits only string should be 1245.")
    }
    
    func test_digits_01()
    {
        let digitsOnly = CardNumberFormatUtility.digitsOnly(forText:"aBcd*^@&$#@12/lgd;'\\45")
        XCTAssert(digitsOnly == "1245",
                  "The digits only string should be 1245.")
    }
    
    func test_digits_02()
    {
        let digitsOnly = CardNumberFormatUtility.digitsOnly(forText:nil)
        XCTAssert(digitsOnly == "",
                  "The digits only string should be empty.")
    }

}
