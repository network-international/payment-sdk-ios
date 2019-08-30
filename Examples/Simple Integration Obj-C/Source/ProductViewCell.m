//
//  CollectionViewCell.m
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "ProductViewCell.h"
#import "Simple_Integration_Obj_C-Swift.h"

#define MIN_PRICE 10
#define MAX_PRICE 50

@interface ProductViewCell ()
@end

@implementation ProductViewCell

@synthesize productLabel;
@synthesize priceLabel;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.priceLabel = [[UILabel alloc] init];
        self.productLabel = [[UILabel alloc] init];
        self.price = MIN_PRICE + arc4random_uniform((uint32_t)(MAX_PRICE - MIN_PRICE + 1));
        self.priceLabel.text = [NSString stringWithFormat: @"AED %d", self.price];
        [self addSubViews];
    }
    return self;
}

- (void)addSubViews {
    self.productLabel.font = [self.productLabel.font fontWithSize:50];
    UIStackView *vStack = [[UIStackView alloc] init];
    [vStack addArrangedSubview: self.productLabel];
    [vStack addArrangedSubview: self.priceLabel];
    vStack.axis = UILayoutConstraintAxisVertical;
    vStack.alignment = UIStackViewAlignmentCenter;
    [self.contentView addSubview: vStack];
    
    [vStack anchorWithTop: self.contentView.topAnchor leading:self.contentView.leadingAnchor bottom:self.contentView.bottomAnchor trailing:self.contentView.trailingAnchor padding:UIEdgeInsetsMake(20, 20, 20, 20) size:CGSizeZero];
    
    self.contentView.layer.cornerRadius = 5;
    self.contentView.layer.masksToBounds = true;
    [self updateBorder: false];
}

- (void)updateBorder:(Boolean)selected {
    UIColor *borderColor = selected
    ? [UIColor colorWithRed:0.40 green:0.73 blue:0.40 alpha:1.0]
    : [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1.0];
    
    [self updateWith:borderColor];
}

- (void)updateWith:(UIColor*)borderColor {
    [self.contentView addBorder: UIRectEdgeTop color: borderColor thickness: 5];
    [self.contentView addBorder: UIRectEdgeBottom color: borderColor thickness: 5];
    [self.contentView addBorder: UIRectEdgeLeft color: borderColor thickness: 5];
    [self.contentView addBorder: UIRectEdgeRight color: borderColor thickness: 5];
}

@end
