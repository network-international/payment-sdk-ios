//
//  SettingsViewController.swift
//  merchant-sample-app
//
//  Created by Niraj Chauhan on 4/24/19.
//  Copyright © 2019 Niraj Chauhan. All rights reserved.
//

import Foundation
import UIKit


class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    weak var settingsDelegate: SettingsDelegate?
    
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var currencyPicker: UIPickerView!
    
    let currencies = ["USD", "AED"]
    var email: String?
    var currency: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.currencyPicker.delegate = self
        self.currencyPicker.dataSource = self
        self.emailInput.delegate = self
        
        self.emailInput.text = email
        if let row = currencies.firstIndex(where: {$0 == currency}) {
            self.currencyPicker.selectRow(row, inComponent: 0, animated: true)
        }
        
        emailInput.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        settingsDelegate?.didCurrencyChange(currencies[row])
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let value = textField.text {
            settingsDelegate?.didEmailChange(value)
        }
    }

    
}
