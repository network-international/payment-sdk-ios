//
//  OrderService.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 03/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderRequestPayload.h"
#import "OrderResponse.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^OrderResponseReturnBlock) (OrderResponse * _Nullable, NSError * _Nullable);

@interface OrderService : NSObject

+ (void)create:(Amount *)amount withAction:(NSString *)action withCompletion:(OrderResponseReturnBlock)completion;

@end

NS_ASSUME_NONNULL_END
