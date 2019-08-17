//
//  NIPanInput.swift
//  NISdk
//
//  Created by Johnny Peter on 16/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class NIPanInputViewController: UIViewController, UITextFieldDelegate {
    let panField: UITextField = UITextField(frame: CGRect(x: 0, y: 0, width: 300.00, height: 30.00))
    @objc let onChangeText: onChangeTextClosure
    
    init(onChangeText: @escaping onChangeTextClosure) {
        self.onChangeText = onChangeText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onPanFieldChange(textField: UITextField) {
        self.onChangeText(textField)
    }
    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        // return NO to not change text
//        return true
//    }
    
    override func viewDidLoad() {
        super .viewDidLoad()
        
        panField.center = self.view.center
        panField.placeholder = "Card Number"
        panField.text = ""
        panField.borderStyle = UITextField.BorderStyle.none
        panField.backgroundColor = .white
        panField.textColor = .black
        panField.delegate = self
        panField.addTarget(self, action: #selector(onPanFieldChange), for: .editingChanged)
        self.view.addSubview(panField)
    }
}
