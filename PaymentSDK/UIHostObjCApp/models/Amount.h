//
//  Amount.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 04/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Amount : NSObject
@property (nonatomic, strong) NSString *currencyCode;
@property (nonatomic, assign) int value;

+ (instancetype)initWithCurrency:(NSString *)code andValue:(int)value;

@end

NS_ASSUME_NONNULL_END
