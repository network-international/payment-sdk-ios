//
//  PaymentSDKHandler.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 30/05/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PaymentSDK/PaymentSDK.h>
#import "PaymentSDKDelegate.h"
NS_ASSUME_NONNULL_BEGIN

typedef void (^VoidBlock) (void);

@interface PaymentSDKHandler : NSObject

@property(nonatomic, strong) PaymentSDKDelegate *paymentDelegate;
@property(nonatomic, strong) Interface *sdk;

+ (id)sharedInstance;
- (void)configureSDK;
- (void)showCardPaymentView:(id)delegate overParent:(UIViewController *)parent with:(VoidBlock)completionBlock;
- (void)showApplePayPaymentView:(id)delegate applePayDelegate:(id)appleDelegate overParent:(UIViewController *)parent andRequest:(PKPaymentRequest *)request withItems:(NSArray *)items with:(VoidBlock)completionBlock;
@end

NS_ASSUME_NONNULL_END
