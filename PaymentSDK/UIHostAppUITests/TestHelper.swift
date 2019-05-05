//
//  TestHelper.swift
//  UIHostAppUITests
//
//  Created by Niraj Chauhan on 5/5/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import XCTest


class TestHelper {
    
    static func type(_ string: String, in app: XCUIApplication){
        for char in string {
            app.keys[String(char)].tap()
            
        }
    }
    
    static func delete(in app: XCUIApplication){
        app.keys["Delete"].tap()
    }
    
}

