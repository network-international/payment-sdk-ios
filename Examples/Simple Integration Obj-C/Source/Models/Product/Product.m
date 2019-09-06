//
//  Product.m
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Product.h"

@interface Product()
@end

@implementation Product

-(instancetype)initWithName:(NSString *)name andAmount:(int) amount {
    if(self = [super init]) {
        self.name = name;
        self.amount = amount;
    }
    return self;
}

@end
