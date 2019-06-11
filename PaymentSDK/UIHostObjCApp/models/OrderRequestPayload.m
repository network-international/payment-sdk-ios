//
//  OrderRequestPayload.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 04/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "OrderRequestPayload.h"

@implementation OrderRequestPayload

+(instancetype)initWith:(Amount *)amount action:(NSString *)action language:(NSString *)language andDescription:(NSString *)description {
    OrderRequestPayload *payload = [[OrderRequestPayload alloc] init];
    payload.amount = amount;
    payload.action = action;
    payload.language = language;
    payload.productDescription = description;
    return payload;
}


@end
