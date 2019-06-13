//
//  ViewController.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 30/05/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PaymentSDK/PaymentSDK.h>
#import "SettingsViewController.h"

@interface CartViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, SettingsDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIStackView *footerStackView;
@property (weak, nonatomic) IBOutlet UILabel *totalTaxLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UILabel *grandTotalLabel;

@property (nonatomic, strong) NSMutableArray *products;
@property (nonatomic, strong) UIButton *cardPaymentButton;
@property (nonatomic, strong) UIButton *applePayButton;
@property (nonatomic, strong) id paymentDelegate;
@property (nonatomic, strong) id applePayDelegate;

@end

