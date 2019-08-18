//
//  NINameInput.swift
//  NISdk
//
//  Created by Johnny Peter on 16/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class NameInputVC: UIViewController, UITextFieldDelegate {
    let nameTextField: UITextField = UITextField()
    
    @objc let onChangeName: onChangeTextClosure
    
    init(onChangeText: @escaping onChangeTextClosure) {
        self.onChangeName = onChangeText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onNameChangeCallback(textField: UITextField) {
        self.onChangeName(textField)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.placeholder = "Cardholder Name"
        nameTextField.text = ""
        nameTextField.borderStyle = .none
        nameTextField.backgroundColor = .white
        nameTextField.textColor = .black
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(onNameChangeCallback), for: .editingChanged)
        nameTextField.setContentHuggingPriority(UILayoutPriority(249), for: .horizontal)
        
        let label = UILabel()
        label.text = "Name"
        
        let hStack = UIStackView(arrangedSubviews: [label, nameTextField])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        hStack.spacing = 70
        
        view.addSubview(hStack)
        
        let stackBackgroundView = UIView()
        stackBackgroundView.addBorder(.bottom, color: UIColor(hexString: "#dbdbdc"), thickness: 1)
        stackBackgroundView.pinAsBackground(to: hStack)
        
        hStack.bindFrameToSuperviewBounds()
    }
}
