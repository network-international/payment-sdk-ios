//
//  CartData.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 06/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CartData : NSObject

@property (nonatomic, strong) NSMutableString *currency;
@property (nonatomic, strong) NSMutableString *email;
@property (nonatomic, assign) double cartTotal;

+(instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
