//
//  Amount.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 04/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "Amount.h"

@implementation Amount

+ (instancetype)initWithCurrency:(NSString *)code andValue:(int)value {
    Amount *amount = [[Amount alloc] init];
    amount.currencyCode = code;
    amount.value = value;
    return amount;
}




@end
