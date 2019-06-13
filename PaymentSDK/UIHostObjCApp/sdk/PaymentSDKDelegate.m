//
//  PaymentSDKDelegate.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 30/05/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "PaymentSDKDelegate.h"
#import "OrderService.h"
#import "Amount.h"
#import "CartData.h"

@implementation PaymentSDKDelegate

- (void)authorizationCompletedWithStatus:(enum AuthorizationStatus)status {
    NSLog(@"Auth Completed with status %ld", (long)status);
}

- (void)authorizationStarted {
    
}

- (void)beginAuthorizationWithDidSelect:(PaymentMethod * _Nonnull)paymentMethod handler:(void (^ _Nonnull)(PaymentAuthorizationLink * _Nullable))completion {
    NSLog(@"Create order");
    
    Amount *amount = [Amount initWithCurrency: [[CartData sharedInstance] currency] andValue: [[CartData sharedInstance] cartTotal]];
    [OrderService create: amount withAction: @"AUTH" withCompletion:^(OrderResponse * _Nonnull order, NSError * _Nonnull error) {
        if (error == nil) {
            if (order) {
                PaymentAuthorizationLink *authLink = [[PaymentAuthorizationLink alloc]initWithHref:order.paymentAuthorizationUrl code:order.code];
                completion(authLink);
            }
        } else {
            NSLog(@"Failed to get authorization link with error : %@", error);
            completion(nil);
        }
    }];
}

- (void)paymentCompletedWith:(enum PaymentStatus)status {
    
}

- (void)paymentStarted {
    
}

@end
