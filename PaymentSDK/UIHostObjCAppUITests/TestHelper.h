//
//  TestHelper.h
//  UIHostObjCAppUITests
//
//  Created by Rahul Dhuri on 11/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestHelper : NSObject

+(void)type:(NSString *)string in:(XCUIApplication *)app;

@end

NS_ASSUME_NONNULL_END
