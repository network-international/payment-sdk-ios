//
//  ViewController.h
//  Simple Integration Obj-C
//
//  Created by Johnny Peter on 29/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <NISdk/NISdk-Swift.h>
#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>

@interface StoreFrontViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CardPaymentDelegate, ApplePayDelegate>
@end

