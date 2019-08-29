//
//  ViewController.m
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "StoreFrontViewController.h"

@interface StoreFrontViewController ()
@property (nonatomic) UIButton *payButton;
@property (nonatomic) PKPaymentButton *applePayButton;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIStackView *buttonStack;
@property (nonatomic) NSArray *pets;
@property (nonatomic) int total;
@property (nonatomic) NSArray<Product *> *selectedItems;

@end

@implementation StoreFrontViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPaymentButtons];
    [self setupCollectionView];
    
    self.title = @"Zoomoji Store";
    self.pets = @[@"🐊", @"🐅", @"🐆", @"🦓", @"🦏", @"🦠", @"🐙", @"🐡", @"🐋", @"🐳"];
}

- (void)setTotal:(int)total {
    _total = total;
    [self showHidePayButtonStack];
}

- (void)setupPaymentButtons {
    self.buttonStack = [UIStackView alloc];
    self.buttonStack.axis = UILayoutConstraintAxisHorizontal;
    self.buttonStack.alignment = UIStackViewAlignmentCenter;
    self.buttonStack.distribution = UIStackViewDistributionFill;
    self.buttonStack.spacing = 20;
    
    UIView *parentView = self.navigationController.view;
    [parentView addSubview: self.buttonStack];
    self.buttonStack.translatesAutoresizingMaskIntoConstraints = false;
    [NSLayoutConstraint activateConstraints:@[
        [self.buttonStack.leadingAnchor constraintEqualToAnchor:parentView.leadingAnchor constant: 20],
        [self.buttonStack.trailingAnchor constraintEqualToAnchor:parentView.trailingAnchor constant: -20],
        [self.buttonStack.heightAnchor constraintEqualToConstant: 50],
        [self.buttonStack.bottomAnchor constraintEqualToAnchor:parentView.bottomAnchor constant: -50]]];
    [self.buttonStack setHidden:YES];
    
    self.payButton = [UIButton alloc];
    self.payButton.backgroundColor = UIColor.blackColor;
    [self.payButton setTitleColor: UIColor.whiteColor forState: UIControlStateNormal];
    [self.payButton setTitleColor: [UIColor colorWithRed:255 green:255 blue:255 alpha:0.6] forState: UIControlStateHighlighted ];
    [self.payButton.titleLabel setFont: [UIFont systemFontOfSize: 14 weight:UIFontWeightMedium]];
    [self.payButton setTitle: @"Pay" forState: UIControlStateNormal];
    self.payButton.layer.cornerRadius = 5;
    [self.payButton addTarget:self action: @selector(payButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonStack addArrangedSubview: self.payButton];
    
    NISdk *sdksharedInstance = [NISdk sharedInstance];
    if([sdksharedInstance deviceSupportsApplePay]) {
        self.applePayButton = [[PKPaymentButton alloc] initWithPaymentButtonType: PKPaymentButtonTypeBuy paymentButtonStyle:PKPaymentButtonStyleBlack];
        [self.applePayButton addTarget: self action:@selector(applePayButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.buttonStack addArrangedSubview: self.applePayButton];
    };

}

- (void)showHidePayButtonStack {
    if(self.total > 0) {
        [self.buttonStack setHidden:NO];
        [self.payButton setTitle:[NSString stringWithFormat:@"Pay Aed %d", self.total] forState: UIControlStateNormal];
    } else {
        [self.buttonStack setHidden:YES];
    }
}

- (void)payButtonTapped {
    
}

- (void)applePayButtonTapped {
    
}

- (void)setupCollectionView {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem: self.pets.count inSection:0];
    self.collectionView = [[UICollectionView alloc]
                           initWithFrame:self.view.bounds collectionViewLayout: [UICollectionViewFlowLayout alloc]];
//    [self.collectionView insertItemsAtIndexPaths: indexPath];
//    [self.collectionView registerClass: ProductViewCell forCellWithReuseIdentifier: "collectionCell"]
}




@end
