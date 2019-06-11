//
//  OrderResponse.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 04/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OrderResponse : NSObject
@property (nonatomic, strong) NSString *orderReference;
@property (nonatomic, strong) NSString *paymentAuthorizationUrl;
@property (nonatomic, strong) NSString *code;
@end

NS_ASSUME_NONNULL_END
