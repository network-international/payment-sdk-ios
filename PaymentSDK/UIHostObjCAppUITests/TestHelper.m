//
//  TestHelper.m
//  UIHostObjCAppUITests
//
//  Created by Rahul Dhuri on 11/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "TestHelper.h"

@implementation TestHelper

+(void)type:(NSString *)string in:(XCUIApplication *)app {
    for (int i = 0; i < string.length; i++) {
        unichar c = [string characterAtIndex: i];
        NSString *str = [NSString stringWithFormat: @"%c", c];
        [[app.keys objectForKeyedSubscript: str] tap];
    }
}

@end
