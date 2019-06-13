//
//  UIHostObjCAppUITests.m
//  UIHostObjCAppUITests
//
//  Created by Rahul Dhuri on 07/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIHostObjCAppUITests-Swift.h"
#import "TestHelper.h"

@interface UIHostObjCAppUITests : XCTestCase
@property(nonatomic, strong) HTTPStubs *httpStubs;
@end

@implementation UIHostObjCAppUITests

-(void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    [[[XCUIApplication alloc] init] launch];
    _httpStubs = [[HTTPStubs alloc] init];
    [_httpStubs setUp];
}

-(void)tearDown {
    [_httpStubs tearDown];
    [super tearDown];
}

-(void)test_shouldLoadProducts {
    XCUIApplication *application = [[XCUIApplication alloc] init];
    XCUIElementQuery *otherElements = application.scrollViews.otherElements;
    XCUIElementQuery *tablesQuery = otherElements.tables;
    XCUIElementQuery *yellowSofaCellsQuery = [tablesQuery.cells containingType: XCUIElementTypeStaticText identifier: @"Yellow Sofa"];
    id value = yellowSofaCellsQuery.element.value;
    XCTAssertNotNil(value, @"There should be a product called 'Yellow Sofa'");
}

-(void)test_shouldIncreaseQuantityOfItemsInCart {
    XCUIApplication *application = [[XCUIApplication alloc] init];
    XCUIElementQuery *otherElements = application.scrollViews.otherElements;
    XCUIElementQuery *tablesQuery = otherElements.tables;
    XCUIElementQuery *yellowSofaCellsQuery = [tablesQuery.cells containingType: XCUIElementTypeStaticText identifier: @"Yellow Sofa"];
    [[yellowSofaCellsQuery.buttons objectForKeyedSubscript: @"Increment"] tap];
    XCUIElement *labelElement = [application.staticTexts objectForKeyedSubscript: @"grandTotal"];
    XCTAssertTrue([labelElement.label isEqualToString: @"Grand total: 72"]);
}

-(void)test_shouldDecreaseQuantityOfItemsInCart {
    XCUIApplication *application = [[XCUIApplication alloc] init];
    XCUIElementQuery *otherElements = application.scrollViews.otherElements;
    XCUIElementQuery *tablesQuery = otherElements.tables;
    XCUIElementQuery *yellowSofaCellsQuery = [tablesQuery.cells containingType: XCUIElementTypeStaticText identifier: @"Yellow Sofa"];
    [[yellowSofaCellsQuery.buttons objectForKeyedSubscript: @"Decrement"] tap];
    XCUIElement *labelElement = [application.staticTexts objectForKeyedSubscript: @"grandTotal"];
    NSString *label = labelElement.label;
    XCTAssertTrue([label isEqualToString: @"Grand total: 43"]);

}

-(void)test_shouldCancelPayByCard {
    XCUIApplication *application = [[XCUIApplication alloc] init];
    XCUIElementQuery *otherElements = application.scrollViews.otherElements;
    [[otherElements.buttons objectForKeyedSubscript: @"Pay by card"] tap];
    
    BOOL isTapped = [[application.buttons objectForKeyedSubscript: @"Cancel"] waitForExistenceWithTimeout:10];
    XCTAssertTrue(isTapped, @"There should be a cancel button after the 'Pay by Card' button is tapped.");
}

-(void)test_shouldPayByCard {
    XCUIApplication *application = [[XCUIApplication alloc] init];
    XCUIElementQuery *otherElements = application.scrollViews.otherElements;
    [[otherElements.buttons objectForKeyedSubscript: @"Pay by card"] tap];
    BOOL isTapped = [[application.buttons objectForKeyedSubscript: @"Cancel"] waitForExistenceWithTimeout:10];
    if (isTapped) {
        [TestHelper type: @"4111111111111111" in: application];
        
        //Type expiry
        [TestHelper type: @"12" in: application];
        [TestHelper type: @"22" in: application];
        
        // Type CVV
        [TestHelper type: @"123" in: application];
        
        // Type Name
        [TestHelper type: @"test" in: application];
        
        [[application.buttons objectForKeyedSubscript: @"Return"] tap];
        [[otherElements.buttons objectForKeyedSubscript: @"Pay"] tap];
        
        BOOL success = [[application.images objectForKeyedSubscript: @"payment_success"] waitForExistenceWithTimeout: 15];
        XCTAssertTrue(success, @"There should be a success tick mark image displayed on successful payment.");
    }
}

@end

