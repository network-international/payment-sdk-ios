//
//  ViewController.m
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <NISdk/NISdk-Swift.h>
#import "Simple_Integration_Obj_C-Swift.h"
#import "StoreFrontViewController.h"
#import "OrderCreationViewController.h"
#import "Product.h"
#import "ProductViewCell.h"

@interface StoreFrontViewController ()
@property (nonatomic) UIButton *payButton;
@property (nonatomic) PKPaymentButton *applePayButton;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIStackView *buttonStack;
@property (nonatomic) NSArray *pets;
@property (nonatomic) int total;
@property (nonatomic) NSMutableArray<Product *> *selectedItems;

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
    self.buttonStack = [[UIStackView alloc] init];
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
    
    self.payButton = [[UIButton alloc] init];
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
    OrderCreationViewController *orderCreationViewController = [[OrderCreationViewController alloc] initWithPaymentAmount: self.total
                                                                                                                      and: self
                                                                                                                    using: Card
                                                                                                                     with: self.selectedItems];
    [orderCreationViewController.view setBackgroundColor: [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]];
    [orderCreationViewController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [self presentViewController: orderCreationViewController animated: NO completion: nil];
}

- (void)applePayButtonTapped {
    OrderCreationViewController *orderCreationViewController = [[OrderCreationViewController alloc] initWithPaymentAmount: self.total
                                                                                                                      and: self
                                                                                                                    using: ApplePay
                                                                                                                     with: self.selectedItems];
    [orderCreationViewController.view setBackgroundColor: [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]];
    [orderCreationViewController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [self presentViewController: orderCreationViewController animated: NO completion: nil];
}

- (void)add:(int)amount emoji:(NSString *)emoji {
    self.total += amount;
    [self.selectedItems addObject: [[Product alloc] initWithName:emoji andAmount:amount]];
}

- (void)remove:(int)amount emoji:(NSString *)emoji {
    self.total -= amount;
    for (Product *product in self.selectedItems) {
        if([product.name isEqualToString:emoji]) {
            [self.selectedItems removeObject: product];
        }
    }
}

- (void)setupCollectionView {
    self.collectionView = [[UICollectionView alloc]
                           initWithFrame:self.view.bounds collectionViewLayout: [[UICollectionViewFlowLayout alloc] init]];
    [self.collectionView registerClass: ProductViewCell.class forCellWithReuseIdentifier: @"collectionCell"];
    self.collectionView.delegate = self;
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = YES;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview: self.collectionView];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    ProductViewCell *pcell = (ProductViewCell *)cell;
    if(pcell.isSelected) {
        [pcell updateBorder: YES];
    } else {
        [pcell updateBorder:NO];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.pets.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ProductViewCell *cell = (ProductViewCell*)[collectionView cellForItemAtIndexPath: indexPath];
    [cell setSelected: YES];
    [cell updateBorder: YES];
    [self add:cell.price emoji:cell.productLabel.text];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    ProductViewCell *cell = (ProductViewCell*)[collectionView cellForItemAtIndexPath: indexPath];
    [cell setSelected: NO];
    [cell updateBorder: NO];
    [self remove:cell.price emoji:cell.productLabel.text];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ProductViewCell *cell = (ProductViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier: @"collectionCell" forIndexPath: indexPath];
    [cell.productLabel setText: (NSString *)[self.pets objectAtIndex: (int)[indexPath item]]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect screenRect = UIScreen.mainScreen.bounds;
    CGFloat screenWidth = screenRect.size.width;
    CGFloat length = (screenWidth / 2) - 20;
    return CGSizeMake(length, length);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 15, 80, 15);
}

- (void) resetSelection {
    self.total = 0;
    [self.selectedItems removeAllObjects];
    [self.collectionView deselectAllItemsWithAnimated: YES resetHandler: ^void (UICollectionViewCell *cell) {
        ProductViewCell *productCell = (ProductViewCell*)cell;
        [productCell updateBorder:false];
    }];
}

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: title message: message preferredStyle: UIAlertControllerStyleAlert];
    [alert addAction: [UIAlertAction actionWithTitle: @"Ok" style:UIAlertActionStyleDefault handler: nil]];
    [self presentViewController: alert animated: YES completion: nil];
}


- (void)paymentDidCompleteWith:(enum PaymentStatus)status {
    if(status == PaymentStatusPaymentSuccess) {
        [self resetSelection];
        [self showAlertWithTitle: @"Payment Successfull" andMessage: @"Your Payment was successfull."];
        return;
    } else if(status == PaymentStatusPaymentFailed) {
        [self showAlertWithTitle: @"Payment Failed" andMessage: @"Your Payment could not be completed."];
    } else if(status == PaymentStatusPaymentCancelled) {
        [self showAlertWithTitle: @"Payment Aborted" andMessage: @"You cancelled the payment request. You can try again!"];
    }
}

@end
