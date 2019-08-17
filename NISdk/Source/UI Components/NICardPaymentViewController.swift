//
//  CardView.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import UIKit

typealias onChangeTextClosure = (UITextField) -> Void

class NICardPaymentViewController: UIViewController {
    var panValue: String?
    
    @objc func onChangePan(textField: UITextField) {
        self.panValue = textField.text
        print(self.panValue ?? "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#EFEFF4")
        let panInputViewController = NIPanInputViewController(onChangeText: onChangePan)
        self.add(panInputViewController)
    }
}
