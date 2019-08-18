//
//  NIExpiryInput.swift
//  NISdk
//
//  Created by Johnny Peter on 16/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class ExpiryInputVC: UIViewController, UITextFieldDelegate {
    let monthTextField: UITextField = UITextField()
    let yearTextField: UITextField = UITextField()
    
    @objc let onChangeMonth: onChangeTextClosure
    @objc let onChangeYear: onChangeTextClosure
    
    init(onChangeMonth: @escaping onChangeTextClosure, onChangeYear: @escaping onChangeTextClosure) {
        self.onChangeMonth = onChangeMonth
        self.onChangeYear = onChangeYear
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onMonthChangeCallback(textField: UITextField) {
        self.onChangeMonth(textField)
    }
    
    @objc func onYearChangeCallback(textField: UITextField) {
        self.onChangeYear(textField)
    }
    
    func setup(textField: UITextField,
            placeholder: String,
            huggingPriority: Float?) {
        textField.placeholder = placeholder
        textField.text = ""
        textField.borderStyle = UITextField.BorderStyle.none
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.delegate = self
        
        if let huggingPriority = huggingPriority {
            textField.setContentHuggingPriority(UILayoutPriority(huggingPriority), for: .horizontal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setup(textField: monthTextField, placeholder: "MM", huggingPriority: nil)
        monthTextField.addTarget(self, action: #selector(onMonthChangeCallback), for: .editingChanged)
        
        self.setup(textField: yearTextField, placeholder: "YY", huggingPriority: 249)
        yearTextField.addTarget(self, action: #selector(onYearChangeCallback), for: .editingChanged)
                
        let label = UILabel()
        label.text = "Expires"
        
        let seperatorLabel = UILabel()
        seperatorLabel.textColor = UIColor(hexString: "#dbdbdc")
        seperatorLabel.text = "/"
        
        let rightHStatch = UIStackView(arrangedSubviews: [monthTextField, seperatorLabel, yearTextField])
        rightHStatch.axis = .horizontal
        rightHStatch.alignment = .center
        rightHStatch.distribution = .fill
        rightHStatch.spacing = 20
        
        
        let rootHStack = UIStackView(arrangedSubviews: [label, rightHStatch])
        rootHStack.axis = .horizontal
        rootHStack.alignment = .center
        rootHStack.distribution = .fill
        rootHStack.spacing = 60
        
        view.addSubview(rootHStack)
        
        let stackBackgroundView = UIView()
        stackBackgroundView.addBorder(.bottom, color: UIColor(hexString: "#dbdbdc") , thickness: 1)
        stackBackgroundView.pinAsBackground(to: rootHStack)
        
        rootHStack.bindFrameToSuperviewBounds()
    }
}
