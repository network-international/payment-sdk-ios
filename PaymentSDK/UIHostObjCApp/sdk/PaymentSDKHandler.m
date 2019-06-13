//
//  PaymentSDKHandler.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 30/05/19.
//  Copyright © 2019 Network International. All rights reserved.
//
#import <PassKit/PassKit.h>
#import "PaymentSDKHandler.h"
#import <PaymentSDK/PaymentSDK-Swift.h>

@implementation PaymentSDKHandler

+ (id)sharedInstance {
    
    static PaymentSDKHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.sdk = [Interface sharedInstance];
    });
    return sharedInstance;
}

- (void)configureSDK {
    // For Apple Pay
    [_sdk configureWith: [[Configuration alloc] initWithMerchantIdentifier: @"merchant.com.example.ngo.TestMerchant"]];
    // For Card onl
//    [_sdk configure];
}

- (void)showCardPaymentView:(id)delegate overParent:(UIViewController *)parent with:(VoidBlock)completionBlock {
    if (delegate == nil) { return; }
    PaymentSDKHandler *handler = [PaymentSDKHandler sharedInstance];
    PaymentAuthorizationHandler *paymentHandler = handler.sdk.paymentAuthorizationHandler;
    if (paymentHandler == nil) { return; }
    [paymentHandler presentCardViewWithOverParent:parent withDelegate:delegate completion:completionBlock];
}


- (void)showApplePayPaymentView:(id)delegate applePayDelegate:(id)appleDelegate overParent:(UIViewController *)parent andRequest:(PKPaymentRequest *)request withItems:(NSArray *)items with:(VoidBlock)completionBlock {
    
    if (delegate == nil) { return; }
    if (appleDelegate == nil) { return; }
    PaymentSDKHandler *handler = [PaymentSDKHandler sharedInstance];
    PaymentAuthorizationHandler *paymentHandler = handler.sdk.paymentAuthorizationHandler;
    if (paymentHandler == nil) { return; }
    
    [paymentHandler presentApplePayViewWithOverParent:parent withDelegate:delegate withApplePayDelegate:appleDelegate withRequest:request items:items completion:completionBlock];
}

@end
