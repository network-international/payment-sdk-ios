//
//  SettingsViewController.h
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 06/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SettingsDelegate <NSObject>

-(void)didEmailChange:(NSString *)email;
-(void)didCurrencyChange:(NSString *)currency;
@end

@interface SettingsViewController : UIViewController <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIPickerView *currencyPicker;
@property (weak, nonatomic) IBOutlet UITextField *emailInput;

@property (nonatomic, strong) NSMutableArray *currencies;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, weak) id<SettingsDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
