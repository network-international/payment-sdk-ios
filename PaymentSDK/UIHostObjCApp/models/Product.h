//
//  Product.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 06/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Info.h"

NS_ASSUME_NONNULL_BEGIN

@interface Product : NSObject

@property (nonatomic, strong) NSString *productId;
@property (nonatomic, assign) double quantity;
@property (nonatomic, strong) NSArray *prices;
@property (nonatomic, strong) Info *info;

@end

NS_ASSUME_NONNULL_END
