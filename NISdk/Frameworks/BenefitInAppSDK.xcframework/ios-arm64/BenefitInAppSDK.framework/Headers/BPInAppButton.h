//
//  BPInAppButton.h
//  BenefitInAppSDK
//
//  Created by Charbel Hassrouny FOO_ on 1/11/18.
//  Copyright © 2018 Charbel Hassrouny FOO_. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BPInAppConfiguration.h"

@protocol BPInAppButtonDelegate;

@interface BPInAppButton : UIView


@property (nonatomic, strong) IBOutlet id <BPInAppButtonDelegate> delegate;

@end

@protocol BPInAppButtonDelegate <NSObject>

- (BPInAppConfiguration *)bpInAppConfiguration;

@end
