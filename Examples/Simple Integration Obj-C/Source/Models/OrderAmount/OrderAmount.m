//
//  OrderAmount.m
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderAmount.h"

@implementation OrderAmount

@synthesize currencyCode;
@synthesize value;


-(instancetype)initWitCurrencyCode:(NSString *)currencyCode andValue:(int) value {
    if(self = [super init]) {
        self.currencyCode = currencyCode;
        self.value = value;
    }
    return self;
}


-(NSDictionary *)dictionary {
    return [[NSDictionary alloc] initWithObjectsAndKeys: self.currencyCode, @"currencyCode", [NSNumber numberWithInt: self.value],  @"value", nil];
}

@end
