//
//  SettingsViewController.m
//  UIHostObjCApp
//
//  Created by Rahul Dhuri on 06/06/19.
//  Copyright © 2019 Network International. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _currencies = [NSMutableArray arrayWithObjects: @"USD", @"AED", nil];
    
    _currencyPicker.delegate = self;
    _currencyPicker.dataSource = self;
    _emailInput.delegate = self;
    
    _emailInput.text = _email;
    [_emailInput addTarget:self action:@selector(textFieldDidChange:) forControlEvents: UIControlEventEditingChanged];
    NSUInteger row = [_currencies indexOfObject: _currency];
    [_currencyPicker selectRow: row inComponent: 0 animated: true];
}

-(void)textFieldDidChange:(UITextField *)textField {
    if ([textField.text length]) {
        [_delegate didEmailChange: textField.text];
    }
}

//MARK: UIPickerview datasource
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_currencies count];
}

//MARK: UIPickerview delegate
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return _currencies[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [_delegate didCurrencyChange: _currencies[row]];
}

@end
