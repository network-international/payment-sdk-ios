//
//  UIHostAppUITests.swift
//  UIHostAppUITests
//
//  Created by Niraj Chauhan on 5/5/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import XCTest

class UIHostAppUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        
    }
    
    func test_productsShouldLoad() {
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        let tablesQuery = elementsQuery.tables
        let yellowSofaCellsQuery = tablesQuery/*@START_MENU_TOKEN@*/.cells.containing(.staticText, identifier:"Yellow Sofa")/*[[".cells.containing(.staticText, identifier:\"Price: 12.15 USD\")",".cells.containing(.staticText, identifier:\"Quantity: 4.0\")",".cells.containing(.staticText, identifier:\"Yellow Sofa\")"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        guard yellowSofaCellsQuery.element.value != nil  else {
            XCTAssert(false, "There should be a product called 'Yellow Sofa'")
            return
        }
    }
    
    func test_increaseQuantity() {
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        let tablesQuery = elementsQuery.tables
        let yellowSofaCellsQuery = tablesQuery/*@START_MENU_TOKEN@*/.cells.containing(.staticText, identifier:"Yellow Sofa")/*[[".cells.containing(.staticText, identifier:\"Price: 12.15 USD\")",".cells.containing(.staticText, identifier:\"Quantity: 4.0\")",".cells.containing(.staticText, identifier:\"Yellow Sofa\")"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        yellowSofaCellsQuery.buttons["Increment"].tap()
        let labelElement = app.staticTexts["grandTotal"]
        XCTAssertEqual(labelElement.label, "Grand total: 72")
    }
    
    func test_decreaseQuantity() {
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        let tablesQuery = elementsQuery.tables
        let yellowSofaCellsQuery = tablesQuery/*@START_MENU_TOKEN@*/.cells.containing(.staticText, identifier:"Yellow Sofa")/*[[".cells.containing(.staticText, identifier:\"Price: 12.15 USD\")",".cells.containing(.staticText, identifier:\"Quantity: 4.0\")",".cells.containing(.staticText, identifier:\"Yellow Sofa\")"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        yellowSofaCellsQuery.buttons["Decrement"].tap()
        let labelElement = app.staticTexts["grandTotal"]
        XCTAssertEqual(labelElement.label, "Grand total: 43")
    }
    
    func test_payByCardCancelButton(){
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        
        elementsQuery.buttons["Pay by card"].tap()
        guard app.buttons["Cancel"].waitForExistence(timeout: 10) else {
            XCTAssert(false, "There should be a cancel button after the 'Pay by Card' button is tapped.")
            return
        }
    }
    
    func test_payByCard(){
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        
        elementsQuery.buttons["Pay by card"].tap()
        
        guard app.buttons["Cancel"].waitForExistence(timeout: 10) else {
            XCTAssert(false, "There should be a cancel button after the 'Pay by Card' button is tapped.")
            return
        }
        //Type card number
        TestHelper.type("4111111111111111", in: app)
        
        //Type expiry
        TestHelper.type("12", in: app)
        TestHelper.type("22", in: app)
        
        // Type CVV
        TestHelper.type("123", in: app)
        
        // Type Name
        TestHelper.type("test", in: app)
        
        app.buttons["Return"].tap()
        
        elementsQuery.buttons["Pay"].tap()
        
        guard app.images["payment_success"].waitForExistence(timeout: 15) else {
            XCTAssert(false, "There should be a success tick mark image displayed on successful payment.")
            return
        }
    }    
}
