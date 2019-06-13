//
//  ApplePaySDKDelegate.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 30/05/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "ApplePaySDKDelegate.h"

@implementation ApplePaySDKDelegate

- (void)applePayContactUpdatedWithDidSelect:(PKContact * _Nonnull)shippingContact handler:(void (^ _Nonnull)(PKPaymentRequestShippingContactUpdate * _Nonnull))completion {
    
}

- (void)applePayPaymentMethodUpdatedWithDidSelect:(PaymentMethod * _Nonnull)paymentMethod handler:(void (^ _Nonnull)(PKPaymentRequestPaymentMethodUpdate * _Nonnull))completion {
    
}

- (void)applePayShippingMethodUpdatedWithDidSelect:(PKShippingMethod * _Nonnull)shippingMethod handler:(void (^ _Nonnull)(PKPaymentRequestShippingMethodUpdate * _Nonnull))completion {
    
}

@end
