//
//  OrderRequestPayload.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 04/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Amount.h"

NS_ASSUME_NONNULL_BEGIN

@interface OrderRequestPayload : NSObject
@property (nonatomic, strong) Amount *amount;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSString *language;
@property (nonatomic, strong) NSString *productDescription;

+(instancetype)initWith:(Amount *)amount action:(NSString *)action language:(NSString *)language andDescription:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
