//
//  Info.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 06/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Info : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *locale;
@property (nonatomic, strong) NSString *productDescription;
@property (nonatomic, strong) NSString *image;

@end

NS_ASSUME_NONNULL_END
