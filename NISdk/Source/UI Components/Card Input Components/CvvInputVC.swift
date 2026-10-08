//
//  NICvvInput.swift
//  NISdk
//
//  Created by Johnny Peter on 16/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import UIKit

class CvvInputVC: UIViewController, UITextFieldDelegate {
    let cvvTextField: UITextField = UITextField()
    @objc let onChangeCvv: onChangeTextClosure
    let cvv: Cvv
    
    init(onChangeText: @escaping onChangeTextClosure, cvv: Cvv) {
        self.onChangeCvv = onChangeText
        self.cvv = cvv
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        cvvTextField.attributedPlaceholder = NSAttributedString(
            string: "Secure Code".localized,
            attributes: [NSAttributedString.Key.foregroundColor: NISdk.sharedInstance.niSdkColors.textFieldPlaceholderColor]
        )
        cvvTextField.text = ""
        cvvTextField.alignForCurrentLanguage()
        cvvTextField.keyboardType = .asciiCapableNumberPad
        cvvTextField.borderStyle = .none
        cvvTextField.backgroundColor = ColorCompatibility.systemBackground
        cvvTextField.textColor = NISdk.sharedInstance.niSdkColors.textFieldLabelColor
        cvvTextField.delegate = self
        cvvTextField.isSecureTextEntry = true;
        cvvTextField.addTarget(self, action: #selector(onCVVChangeCallback), for: .editingChanged)
        cvvTextField.setContentHuggingPriority(UILayoutPriority(249), for: .horizontal)
        
        let label = UILabel()
        label.textColor = NISdk.sharedInstance.niSdkColors.textFieldLabelColor
        label.text = "CVV".localized
        
        let hStack = UIStackView(arrangedSubviews: [label, cvvTextField])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        if (hStack.getUILayoutDirection() == .rightToLeft) {
            hStack.spacing = 20
        } else {
            hStack.spacing = 80
        }
        
        view.addSubview(hStack)
        
        let stackBackgroundView = UIView()
        stackBackgroundView.backgroundColor = UIColor.clear
        stackBackgroundView.addBorder(.bottom, color: NISdk.sharedInstance.niSdkColors.payPageDividerColor, thickness: 1)
        stackBackgroundView.pinAsBackground(to: hStack)
        
        hStack.bindFrameToSuperviewBounds()
    }
    
    @objc func onCVVChangeCallback(textField: UITextField) {
        self.onChangeCvv(textField)
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        return textField.hasReachedCharacterLimit(for: string, in: range, with: cvv.length) &&
            textField.hasOnlyDigits(string: string)
    }
}
