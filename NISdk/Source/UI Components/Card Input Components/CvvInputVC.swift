//
//  NICvvInput.swift
//  NISdk
//
//  Created by Johnny Peter on 16/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class CvvInputVC: UIViewController, UITextFieldDelegate {
    let cvvTextField: UITextField = UITextField()
    @objc let onChangeCvv: onChangeTextClosure
    
    init(onChangeText: @escaping onChangeTextClosure) {
        self.onChangeCvv = onChangeText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cvvTextField.placeholder = "Secure Code"
        cvvTextField.text = ""
        cvvTextField.borderStyle = .none
        cvvTextField.backgroundColor = .white
        cvvTextField.textColor = .black
        cvvTextField.delegate = self
        cvvTextField.isSecureTextEntry = true;
        cvvTextField.addTarget(self, action: #selector(onCVVChangeCallback), for: .editingChanged)
        cvvTextField.setContentHuggingPriority(UILayoutPriority(249), for: .horizontal)
        
        let label = UILabel()
        label.text = "CVV"
        
        let hStack = UIStackView(arrangedSubviews: [label, cvvTextField])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        hStack.spacing = 80
        
        view.addSubview(hStack)
        
        let stackBackgroundView = UIView()
        stackBackgroundView.addBorder(.bottom, color: UIColor(hexString: "#dbdbdc"), thickness: 1)
        stackBackgroundView.pinAsBackground(to: hStack)
        
        hStack.bindFrameToSuperviewBounds()
    }
    
    @objc func onCVVChangeCallback(textField: UITextField) {
        self.onChangeCvv(textField)
    }
}
