//
//  OrderRequest.h
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#ifndef OrderRequest_h
#define OrderRequest_h

#import "OrderAmount.h"

@interface OrderRequest : NSObject

@property (nonatomic) NSString *action;
@property (nonatomic) OrderAmount *amount;

-(id)initWithAction:(NSString *)action andAmount:(OrderAmount *)amount;
-(NSDictionary *)dictionary;

@end


#endif /* OrderRequest_h */
