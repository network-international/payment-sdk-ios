//
//  NIPanInput.swift
//  NISdk
//
//  Created by Johnny Peter on 16/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import UIKit

class PanInputVC: UIViewController, UITextFieldDelegate {
    let panTextField: UITextField = UITextField()
    let panCharacterLimit = 16
    @objc let onChangeText: onChangeTextClosure
    
    init(onChangeText: @escaping onChangeTextClosure) {
        self.onChangeText = onChangeText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        panTextField.attributedPlaceholder = NSAttributedString(
            string:"Card Number".localized,
            attributes: [NSAttributedString.Key.foregroundColor: NISdk.sharedInstance.niSdkColors.textFieldPlaceholderColor]
        )

        panTextField.keyboardType = .asciiCapableNumberPad
        panTextField.text = ""
        panTextField.alignForCurrentLanguage()
        panTextField.borderStyle = .none
        panTextField.backgroundColor = ColorCompatibility.systemBackground
        panTextField.textColor = NISdk.sharedInstance.niSdkColors.textFieldLabelColor
        panTextField.delegate = self
        panTextField.addTarget(self, action: #selector(onPanFieldChange), for: .editingChanged)
        panTextField.setContentHuggingPriority(UILayoutPriority(249), for: .horizontal)

        let label = UILabel()
        label.textColor = NISdk.sharedInstance.niSdkColors.textFieldLabelColor
        label.text = "Number".localized
        
        let hStack = UIStackView(arrangedSubviews: [label, panTextField])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        if (hStack.getUILayoutDirection() == .rightToLeft) {
            hStack.spacing = 20
        } else {
            hStack.spacing = 50
        }
        
        view.addSubview(hStack)
        
        let stackBackgroundView = UIView()
        stackBackgroundView.addBorder(.bottom, color: NISdk.sharedInstance.niSdkColors.payPageDividerColor , thickness: 1)
        stackBackgroundView.pinAsBackground(to: hStack)
        
        hStack.bindFrameToSuperviewBounds()
    }
    
    @objc func onPanFieldChange(textField: UITextField) {
        self.onChangeText(textField)
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        return textField.hasReachedCharacterLimit(for: string, in: range, with: panCharacterLimit) && textField.hasOnlyDigits(string: string)
    }
}
