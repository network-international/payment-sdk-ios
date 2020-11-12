//
//  OrderCreationViewController.m
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "Simple_Integration_Obj_C-Swift.h"
#import "OrderCreationViewController.h"
#import "OrderRequest.h"
#import "OrderAmount.h"

@import NISdk;

@interface OrderCreationViewController ()
@property (nonatomic) int paymentAmount;
@property (nonatomic) NSArray<Product*> *purchasedItems;
@property (nonatomic) PaymentMethod paymentMethod;
@property (nonatomic) id<CardPaymentDelegate> cardPaymentDelegate;
@property (nonatomic) PKPaymentRequest *paymentRequest;
@end

@implementation OrderCreationViewController

- (instancetype)initWithPaymentAmount:(int)amount and:(id<CardPaymentDelegate>)cardPaymentDelegate using:(PaymentMethod)paymentMethod with:(NSArray<Product*> *)purchasedItems {
    self = [super init];
    if(self) {
        self.cardPaymentDelegate = cardPaymentDelegate;
        self.paymentAmount = amount;
        self.paymentMethod = paymentMethod;
        self.purchasedItems = purchasedItems;
    }
    
    if(self.paymentMethod == ApplePay) {
        self.paymentRequest = [[PKPaymentRequest alloc] init];
        NSString *merchantId = @"";
        NSAssert(merchantId.length > 0, @"You need to add your apple pay merchant ID above");
        self.paymentRequest.merchantIdentifier = merchantId;
        self.paymentRequest.countryCode = @"AE";
        self.paymentRequest.currencyCode = @"AED";
        self.paymentRequest.requiredShippingContactFields = [[NSSet alloc] initWithObjects: PKContactFieldPostalAddress, PKContactFieldEmailAddress, PKContactFieldPhoneNumber, nil];
        self.paymentRequest.merchantCapabilities = PKMerchantCapabilityDebit | PKMerchantCapabilityCredit | PKMerchantCapability3DS;
        self.paymentRequest.requiredBillingContactFields = [[NSSet alloc] initWithObjects: PKContactFieldPostalAddress, PKContactFieldName, nil];
        NSMutableArray<PKPaymentSummaryItem *> *summaryItems = [[NSMutableArray alloc] initWithCapacity: purchasedItems.count + 1];
        for (Product *item in self.purchasedItems) {
            [summaryItems addObject: [PKPaymentSummaryItem
                                      summaryItemWithLabel: item.name
                                      amount: [[NSDecimalNumber alloc] initWithFloat: item.amount]]];
        }
        [summaryItems addObject: [PKPaymentSummaryItem
                                  summaryItemWithLabel: @"NGenius merchant"
                                  amount: [[NSDecimalNumber alloc] initWithFloat: amount]]];
        self.paymentRequest.paymentSummaryItems = summaryItems;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    UILabel * authorizationLabel = [[UILabel alloc] init];
    [authorizationLabel setTextColor: UIColor.whiteColor];
    authorizationLabel.text = @"Creating Order...";
    
    UIActivityIndicatorView * spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    [spinner setHidden: true];
    [spinner setColor: UIColor.whiteColor];
    [spinner startAnimating];
    
    UIStackView *vStack = [[UIStackView alloc] initWithArrangedSubviews: [[NSArray alloc] initWithObjects: authorizationLabel, spinner, nil] ];
    [vStack setAxis: UILayoutConstraintAxisVertical];
    [vStack setSpacing: 0];
    [vStack setAlignment: UIStackViewAlignmentCenter];
    
    [self.view addSubview: vStack];
    [vStack anchorWithTop: nil leading: self.view.safeAreaLayoutGuide.leadingAnchor bottom: nil trailing: self.view.safeAreaLayoutGuide.trailingAnchor padding: UIEdgeInsetsZero size: CGSizeMake(0, 100)];
    
    [NSLayoutConstraint activateConstraints:@[
      [[vStack centerXAnchor] constraintEqualToAnchor: self.view.centerXAnchor],
      [[vStack centerYAnchor] constraintEqualToAnchor: self.view.centerYAnchor]]];
    
    [self createOrder];
   
}

- (void)dismissVC {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self dismissViewControllerAnimated: false completion: nil];
    });
}

- (void)displayErrorAndClose:(NSError*)error {
    NSString *errorTitle = @"";
    if(error != nil) {
        NSDictionary *userInfo = [error userInfo];
        errorTitle = (NSString*)[userInfo objectForKey: @"NSLocalizedDescription"];
        if(errorTitle == nil) {
            errorTitle = @"Unknown Error";
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorTitle message:@"" preferredStyle: UIAlertControllerStyleAlert];
        [alert addAction: [UIAlertAction actionWithTitle: @"Ok" style:UIAlertActionStyleDefault handler: ^(UIAlertAction * action){
            [self dismissVC];
        }]];
        [self presentViewController:alert animated:true completion:nil];
        
    });
}

- (void)createOrder {
    OrderRequest *orderRequest = [[OrderRequest alloc] initWithAction: @"SALE" andAmount: [[OrderAmount alloc] initWitCurrencyCode: @"AED" andValue: self.paymentAmount * 100]];
    
    NSDictionary *requestHeaders = [[NSDictionary alloc] initWithObjectsAndKeys: @"application/json", @"Content-Type", nil];
    
    NSData *orderRequestData = [NSJSONSerialization dataWithJSONObject:[orderRequest dictionary]  options: NSJSONWritingSortedKeys error: nil];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: @"http://localhost:3000/api/createOrder"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval: 10.0];
    
    [request setHTTPMethod: @"POST"];
    [request setAllHTTPHeaderFields: requestHeaders];
    [request setHTTPBody:orderRequestData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    @try {
        __weak OrderCreationViewController *weakSelf = self;
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest: request completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
            if(error != nil) {
                [weakSelf displayErrorAndClose: error];
                return;
            }
            if(data != nil) {
                OrderResponse *orderResponse = [OrderResponse decodeFromData: data error: nil];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [weakSelf dismissViewControllerAnimated: NO completion: ^() {
                        NISdk *sdkInstance = [NISdk sharedInstance];
                        if(weakSelf.paymentMethod == Card) {
                            [sdkInstance showCardPaymentViewWithCardPaymentDelegate: weakSelf.cardPaymentDelegate
                                                                         overParent:(UIViewController *)weakSelf.cardPaymentDelegate
                                                                                for: orderResponse];
                        } else {
                            [sdkInstance initiateApplePayWithApplePayDelegate: (id<ApplePayDelegate>)weakSelf.cardPaymentDelegate
                                                          cardPaymentDelegate: weakSelf.cardPaymentDelegate
                                                                   overParent: (UIViewController *)weakSelf.cardPaymentDelegate
                                                                          for: orderResponse
                                                                         with: self.paymentRequest];
                        }
                    }];
                });
            }
        }];
        [dataTask resume];
    } @catch (NSException *exception) {
        __weak OrderCreationViewController *weakSelf = self;
        NSMutableDictionary * info = [NSMutableDictionary dictionary];
        [info setValue:exception.name forKey:@"ExceptionName"];
        [info setValue:exception.reason forKey:@"ExceptionReason"];
        [info setValue:exception.callStackReturnAddresses forKey:@"ExceptionCallStackReturnAddresses"];
        [info setValue:exception.callStackSymbols forKey:@"ExceptionCallStackSymbols"];
        [info setValue:exception.userInfo forKey:@"ExceptionUserInfo"];
        NSError *error = [[NSError alloc] initWithDomain: NSURLErrorDomain code: 0 userInfo:info];
        [weakSelf displayErrorAndClose: error];
    }
}

@end
