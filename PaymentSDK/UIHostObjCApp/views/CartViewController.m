//
//  ViewController.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 30/05/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "CartViewController.h"
#import <PaymentSDK/PaymentSDK.h>
#import "PaymentSDKHandler.h"
#import "PaymentSDKDelegate.h"
#import "ApplePaySDKDelegate.h"
#import "CartItemTableViewCell.h"
#import "Product.h"
#import "CartData.h"
#import "Price.h"
#import <PassKit/PassKit.h>

@interface CartViewController ()

@end

@implementation CartViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerTableViewCells];
    [self loadProducts];
    [self renderButtons];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.estimatedRowHeight = 150;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.alwaysBounceVertical = false; //Disable scroll
    
    [[PaymentSDKHandler sharedInstance] configureSDK];
    _paymentDelegate = [PaymentSDKDelegate new];
    _applePayDelegate = [ApplePaySDKDelegate new];
    
    [self initializeCartData];
}

-(void)initializeCartData {
    [[CartData sharedInstance] setCurrency: [NSMutableString stringWithString: @"USD"]];
    [[CartData sharedInstance] setEmail: [NSMutableString stringWithString: @"test@gmail.com"]];
    [[CartData sharedInstance] setCartTotal: 0.0];
}

-(void)registerTableViewCells {
    [_tableView registerNib: [UINib nibWithNibName: @"CartItemTableViewCell" bundle:nil] forCellReuseIdentifier: @"CartItemTableViewCell"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    SettingsViewController *settingsViewController = segue.destinationViewController;
    settingsViewController.currency = [[CartData sharedInstance] currency];
    settingsViewController.email = [[CartData sharedInstance] email];
    settingsViewController.delegate = self;
}


-(UIButton *)getApplePayButton {
    UIButton *button = [PKPaymentButton buttonWithType: PKPaymentButtonTypeBuy style: PKPaymentButtonStyleBlack];
    [button addTarget: self action: @selector(payWithApplePayAction) forControlEvents: UIControlEventTouchUpInside];
    return button;
}

-(void)payWithApplePayAction {
    [[PaymentSDKHandler sharedInstance] showApplePayPaymentView: _paymentDelegate applePayDelegate: _applePayDelegate overParent: self andRequest: [self getApplePayRequest] withItems: [self getAppleSummaryItems] with:^{
        NSLog(@"Showing apple payment view!");
    }];
}

-(UIButton *)getCardPayButton {
    UIButton *button = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    button.backgroundColor = [UIColor clearColor];
    button.layer.cornerRadius = 5;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [[UIColor colorWithRed: 0.89 green: 0.89 blue: 0.89 alpha: 1.0] CGColor];
    button.contentEdgeInsets = UIEdgeInsetsMake(10, 15, 10, 15);
    [button setTitle: @"Pay by card" forState: UIControlStateNormal];
    [button addTarget: self action: @selector(payByCardAction:) forControlEvents: UIControlEventTouchUpInside];
    return button;
}

-(void)payByCardAction:(UIButton *)sender {
    [[PaymentSDKHandler sharedInstance] showCardPaymentView:_paymentDelegate overParent:self with:^{
        NSLog(@"Showing card payment view!");
    }];
}

-(PKPaymentRequest *)getApplePayRequest {
    PKPaymentRequest *request = [PKPaymentRequest new];
    request.countryCode = @"AE";
    request.currencyCode = [[CartData sharedInstance] currency];
    request.requiredShippingContactFields = [NSSet setWithObjects: PKContactFieldPostalAddress, PKContactFieldEmailAddress, PKContactFieldPhoneNumber, nil];
    request.merchantCapabilities = PKMerchantCapability3DS|PKMerchantCapabilityDebit|PKMerchantCapabilityCredit;
    return request;
}

-(NSArray *)getAppleSummaryItems {    
    NSDecimalNumber *total = [NSDecimalNumber decimalNumberWithMantissa: 0 exponent: -2 isNegative: false];
    NSMutableArray *items = [NSMutableArray new];
    for (Product *product in _products) {
        if (product.quantity > 0) {
            [items addObject: product];
        }
    }
    NSMutableArray *filteredItems = [NSMutableArray new];
    
    for (Product *product in items) {
        Price *price = [self filterPriceFrom: product.prices];
        double productPrice = 0.0;
        if (price) {
            productPrice = price.total + product.quantity;
        }
        NSDecimalNumber *decimal = [NSDecimalNumber decimalNumberWithMantissa: productPrice exponent: -2 isNegative: false];
        total = [decimal decimalNumberByAdding: total];
        PKPaymentSummaryItem *item = [[PKPaymentSummaryItem alloc] init];
        [item setLabel: product.info.name];
        [item setAmount: decimal];
        [filteredItems addObject: item];
    }
    PKPaymentSummaryItem *item = [[PKPaymentSummaryItem alloc] init];
    [item setLabel: @"Total"];
    [item setAmount: total];
    [filteredItems addObject: item];
    return filteredItems;
}


-(UIStackView *)getStackView {
    UIStackView *stackView = [[UIStackView alloc] initWithFrame: CGRectMake(0, 0, 20, 20)];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    [stackView setAlignment: UIStackViewAlignmentCenter];
    stackView.spacing = 30.0;
    return stackView;
}

-(void)renderButtons {
    _cardPaymentButton = [self getCardPayButton];
    UIStackView *cardStackView = [self getStackView];
    [cardStackView addArrangedSubview:_cardPaymentButton];
    [_footerStackView addArrangedSubview:cardStackView];
    
    _applePayButton = [self getApplePayButton];
    UIStackView *applePayStackView = [self getStackView];
    [applePayStackView addArrangedSubview: _applePayButton];
    [_footerStackView addArrangedSubview: applePayStackView];
}

-(void)loadProducts {
    NSURL *url = [[NSBundle mainBundle] URLForResource: @"products_en" withExtension: @"json"];
    NSData *data = [NSData dataWithContentsOfURL: url options: NSDataReadingMappedIfSafe error:nil];
    NSArray *products = [NSJSONSerialization JSONObjectWithData: data
                                                                 options: NSJSONReadingMutableLeaves
                                                                   error: nil];
    if (_products == nil) {
        _products = [NSMutableArray new];
    }
    for (NSDictionary *productDictionary in products) {
        Product *product = [Product new];
        product.productId = [productDictionary objectForKey: @"id"];
        product.info = [self parseInfofrom: [productDictionary objectForKey: @"info"]];
        product.prices = [self parsePricesFrom: [productDictionary objectForKey: @"prices"]];
        NSNumber *qty = [productDictionary objectForKey: @"quantity"];
        product.quantity = [qty doubleValue];
        [_products addObject:product];
    }
    [_tableView reloadData];
}

-(Info *)parseInfofrom:(NSDictionary *)dictionary {
    Info *info = [Info new];
    info.name = [dictionary objectForKey: @"name"];
    info.locale = [dictionary objectForKey: @"locale"];
    info.productDescription = [dictionary objectForKey: @"productDescription"];
    info.image = [dictionary objectForKey: @"image"];
    
    return info;
}

-(NSArray *)parsePricesFrom:(NSArray *)priceArray {
    NSMutableArray *prices = [NSMutableArray new];
    for (NSDictionary *dictionary in priceArray) {
        Price *price = [Price new];
        NSNumber *tax = [dictionary objectForKey: @"tax"];
        NSNumber *total = [dictionary objectForKey: @"total"];
        NSString *currency = [dictionary objectForKey: @"currency"];
        
        price.tax = [tax doubleValue];
        price.total = [total doubleValue];
        price.currency = currency;
        [prices addObject: price];
    }
    return prices;
}

-(void)updateTotal {
    double total = 0.0;
    double totalTax = 0.0;
    for (Product *product in _products) {
        Price *price = [self filterPriceFrom: product.prices];
        if (price) {
            if (price.total) {
                total += product.quantity * price.total;
            }
            if (price.tax) {
                totalTax += product.quantity * price.tax;
            }
        }
    }
    
    _totalLabel.text = [NSString stringWithFormat: @"Total: %0.2lf",(total/100)];
    _totalTaxLabel.text = [NSString stringWithFormat: @"Tax: %0.2lf",(totalTax/100)];
    [[CartData sharedInstance] setCartTotal: (total + totalTax)];
    _grandTotalLabel.text = [NSString stringWithFormat: @"Grand total: %0.2lf", ([[CartData sharedInstance] cartTotal] / 100)];
}


-(void)stepperValueChanged:(UIStepper *)sender {
    Product *product = _products[sender.tag];
    product.quantity = sender.value;
    [_tableView reloadData];
}


-(Price *)filterPriceFrom:(NSArray *)prices {
    for (Price *price in prices) {
        if ([price.currency isEqualToString: [[CartData sharedInstance] currency]]) {
            return price;
        }
    }
    return nil;
}

//MARK: UITableViewDatasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_products count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CartItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"CartItemTableViewCell" forIndexPath: indexPath];
    Product *product = _products[indexPath.row];
    
    Price *price = [self filterPriceFrom: product.prices];
    double productPrice = 0.0;
    if (price) {
        productPrice = price.total / 100;
    }
    cell.productPrice.text = [NSString stringWithFormat: @"Price: %lf %@", productPrice, [[CartData sharedInstance] currency]];
    cell.productImage.image = [UIImage imageNamed: product.info.image];
    cell.productTitle.text = product.info.name;
    cell.productQuantity.text = [NSString stringWithFormat: @"Quantity: %lf", product.quantity];

    cell.stepper.tag = indexPath.row;
    cell.stepper.value = product.quantity;
    [cell.stepper addTarget: self action: @selector(stepperValueChanged:) forControlEvents: UIControlEventValueChanged];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}


//MARK: UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[tableView indexPathsForVisibleRows] lastObject]) {
        if ([[tableView indexPathsForVisibleRows] lastObject] == indexPath) {
            [self updateTotal];
        }
    }
}

//MARK: Settings delegate
-(void)didEmailChange:(NSString *)email {
    [[CartData sharedInstance] setEmail: [NSMutableString stringWithString: email]];
    [_tableView reloadData];
}

-(void)didCurrencyChange:(NSString *)currency {
    [[CartData sharedInstance] setCurrency: [NSMutableString stringWithString: currency]];
    [_tableView reloadData];
}

@end
