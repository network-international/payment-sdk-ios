//
//  OrderCreationViewController.h
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>
#import "PaymentMethod.h"
#import "Product.h"


@import NISdk;

NS_ASSUME_NONNULL_BEGIN

@interface OrderCreationViewController : UIViewController

- (instancetype)initWithPaymentAmount:(int)amount and:(id<CardPaymentDelegate>)cardPaymentDelegate using:(PaymentMethod)paymentMethod with:(NSArray<Product*> *)purchasedItems;

@end

NS_ASSUME_NONNULL_END
