//
//  product.h
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#ifndef product_h
#define product_h

@interface Product : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) int amount;

-(id)initWithName:(NSString *)name andAmount:(int) amount;

@end


#endif /* product_h */
