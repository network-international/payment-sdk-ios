//
//  BPDLPaymentCallBackItem.h
//  FooPay
//
//  Created by Charbel Hassrouny FOO_ on 1/10/18.
//  Copyright © 2018 FOO. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PaymentCallBackStatusCancel,
    PaymentCallBackStatusSuccess,
    PaymentCallBackStatusFail
} PaymentCallBackStatus;

@interface BPDLPaymentCallBackItem : NSObject

@property (nonatomic) PaymentCallBackStatus status;
@property (strong, nonatomic) NSString *merchantName;
@property (strong, nonatomic) NSString *cardNumber;
@property (strong, nonatomic) NSString *currency;
@property (strong, nonatomic) NSString *currencyCode;
@property (strong, nonatomic) NSString *amount;
@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) NSString *referenceId;

- (instancetype)initWithDeepLinkURL:(NSURL *)url;


@end
