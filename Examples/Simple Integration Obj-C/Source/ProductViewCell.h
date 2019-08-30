//
//  CollectionViewCell.h
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProductViewCell : UICollectionViewCell

@property (nonatomic) UILabel *productLabel;
@property (nonatomic) UILabel *priceLabel;
@property (nonatomic) int price;

- (void)updateBorder:(Boolean)selected;

@end

NS_ASSUME_NONNULL_END
