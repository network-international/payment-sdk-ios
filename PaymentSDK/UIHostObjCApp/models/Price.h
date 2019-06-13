//
//  Price.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 06/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Price : NSObject

@property (nonatomic, assign) double total;
@property (nonatomic, assign) double tax;
@property (nonatomic, strong) NSString *currency;

@end

NS_ASSUME_NONNULL_END
