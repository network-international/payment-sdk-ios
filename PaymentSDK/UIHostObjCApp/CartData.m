//
//  CartData.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 06/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "CartData.h"

@implementation CartData

+(instancetype)sharedInstance {
    static CartData *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
