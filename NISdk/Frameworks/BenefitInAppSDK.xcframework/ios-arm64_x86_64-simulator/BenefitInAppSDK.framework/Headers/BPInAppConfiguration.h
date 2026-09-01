//
//  BPInAppConfiguration.h
//  tempBN
//
//  Created by Charbel Hassrouny FOO_ on 1/11/18.
//  Copyright © 2018 Charbel Hassrouny FOO_. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BPInAppConfiguration : NSObject

@property (strong, nonatomic) NSString *appId;
@property (strong, nonatomic) NSString *secretKey;
@property (strong, nonatomic) NSString *amount;
@property (strong, nonatomic) NSString *currencyCode;
@property (strong, nonatomic) NSString *merchantId;
@property (strong, nonatomic) NSString *merchantName;
@property (strong, nonatomic) NSString *merchantCity;
@property (strong, nonatomic) NSString *countryCode;
@property (strong, nonatomic) NSString *referenceId;
@property (strong, nonatomic) NSString *merchantCategoryCode;

@property (strong, nonatomic) NSString *callBackTag;

- (instancetype)initWithAppId:(NSString *)appId
                 andSecretKey:(NSString *)secretKey
                    andAmount:(NSString *)amount
              andCurrencyCode:(NSString *)currencyCode
                andMerchantId:(NSString *)merchantId
              andMerchantName:(NSString *)merchantName
              andMerchantCity:(NSString *)merchantCity
               andCountryCode:(NSString *)countryCode
        andMerchantCategoryId:(NSString *)merchantCategoryCode
               andReferenceId:(NSString *)referenceId
               andCallBackTag:(NSString *)callBackTag;

@end
