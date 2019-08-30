//
//  OrderAmount.h
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#ifndef OrderAmount_h
#define OrderAmount_h

@interface OrderAmount : NSObject

@property (nonatomic) NSString *currencyCode;
@property (nonatomic) int value;

-(instancetype)initWitCurrencyCode:(NSString *)currencyCode andValue:(int) value;
-(NSDictionary *)dictionary;

@end

#endif /* OrderAmount_h */
