//
//  OrderService.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 03/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "OrderService.h"

#define endpoint @"http://localhost:3000/api/create_payment_order"

@implementation OrderService

+ (void)create:(Amount *)amount withAction:(NSString *)action withCompletion:(OrderResponseReturnBlock)completion {
    NSURL *url = [NSURL URLWithString: endpoint];
    if (url == nil) { return; }
    
    OrderRequestPayload *payload = [OrderRequestPayload initWith: amount action: action language: @"en" andDescription: @"Purchase from merchant sample app"];
    NSMutableDictionary *amountDictionary = [[NSMutableDictionary alloc] initWithCapacity: 0];
    [amountDictionary setObject:amount.currencyCode forKey: @"currencyCode"];
    [amountDictionary setValue:[NSNumber numberWithInt: amount.value] forKey: @"value"];
    
    NSMutableDictionary *body = [[NSMutableDictionary alloc] initWithCapacity: 0];
    [body setObject:amountDictionary forKey: @"amount"];
    [body setObject:payload.action forKey: @"action"];
    [body setObject:payload.language forKey: @"language"];
    [body setObject:payload.productDescription forKey: @"description"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject: body options: 0 error: nil];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: data];
    [request setValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
    [request setValue: @"application/json" forHTTPHeaderField: @"Accept"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest: request completionHandler: ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            NSError *parseError;
            if (data != nil) {
                NSDictionary* responseDictionary = [NSJSONSerialization JSONObjectWithData: data
                                                                                   options: NSJSONReadingMutableLeaves
                                                                                     error: &parseError];
                
                OrderResponse *orderResponse = [[OrderResponse alloc] init];
                orderResponse.orderReference = [responseDictionary objectForKey: @"orderReference"];
                orderResponse.paymentAuthorizationUrl = [responseDictionary objectForKey: @"paymentAuthorizationUrl"];
                orderResponse.code = [responseDictionary objectForKey: @"code"];
                completion(orderResponse, nil);
            }
            completion(nil, parseError);
        } else {
            completion(nil, error);
        }
    }];
    
    [task resume];
}

@end
