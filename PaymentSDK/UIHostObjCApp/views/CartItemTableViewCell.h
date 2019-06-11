//
//  CartItemTableViewCell.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 06/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CartItemTableViewCell : UITableViewCell 

@property (weak, nonatomic) IBOutlet UIImageView *productImage;
@property (weak, nonatomic) IBOutlet UILabel *productTitle;
@property (weak, nonatomic) IBOutlet UILabel *productQuantity;
@property (weak, nonatomic) IBOutlet UILabel *productPrice;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;

@end

NS_ASSUME_NONNULL_END
