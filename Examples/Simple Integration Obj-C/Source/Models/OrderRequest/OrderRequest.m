//
//  OrderRequest.m
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderRequest.h"
#import "OrderAmount.h"

@implementation OrderRequest

@synthesize action;
@synthesize amount;

-(id)initWithAction:(NSString *)action andAmount:(OrderAmount *) amount {
    if(self = [super init]) {
        self.action = action;
        self.amount = amount;
    }
    return self;
}
-(NSDictionary *)dictionary {
    return [[NSDictionary alloc] initWithObjectsAndKeys: self.action, @"action", [self.amount dictionary] , @"amount", nil];
}

@end
