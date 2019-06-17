//
//  ApplePaySDKDelegate.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 30/05/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "ApplePaySDKDelegate.h"
#import <PassKit/PassKit.h>
@implementation ApplePaySDKDelegate

- (void)applePayContactUpdatedWithDidSelect:(PKContact * _Nonnull)shippingContact handler:(void (^ _Nonnull)(PKPaymentRequestShippingContactUpdate * _Nonnull))completion {
    NSLog(@"Apple pay contact updated: \(shippingContact)");
    completion([[PKPaymentRequestShippingContactUpdate alloc] initWithErrors: nil paymentSummaryItems: [NSArray new] shippingMethods: [NSArray new]]);
}

- (void)applePayPaymentMethodUpdatedWithDidSelect:(PaymentMethod * _Nonnull)paymentMethod handler:(void (^ _Nonnull)(PKPaymentRequestPaymentMethodUpdate * _Nonnull))completion {
    NSLog(@"Apple pay payment method updated: \(paymentMethod)");
    completion([[PKPaymentRequestPaymentMethodUpdate alloc] initWithPaymentSummaryItems: [NSArray new]]);
}

- (void)applePayShippingMethodUpdatedWithDidSelect:(PKShippingMethod * _Nonnull)shippingMethod handler:(void (^ _Nonnull)(PKPaymentRequestShippingMethodUpdate * _Nonnull))completion {
    NSLog(@"Apple pay shipping method updated: \(shippingMethod)");
    completion([[PKPaymentRequestShippingMethodUpdate alloc] initWithPaymentSummaryItems: [NSArray new]]);
}

@end
