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
    var expiryMonthValue: String?
    var expiryYearValue: String?
    
    @objc func onChangePan(textField: UITextField) {
        self.panValue = textField.text
        print(self.panValue ?? "")
    }
    
    @objc func onChangeMonth(textField: UITextField) {
        self.expiryMonthValue = textField.text
        print(self.expiryMonthValue ?? "")
    }
    
    @objc func onChangeYear(textField: UITextField) {
        self.expiryYearValue = textField.text
        print(self.expiryYearValue ?? "")
    }

    func setupCardInputForm() {
        let panInputVC = PanInputVC(onChangeText: onChangePan)
        let expiryVC = ExpiryInputVC(onChangeMonth: onChangeMonth, onChangeYear: onChangeYear)

        let panContainer = UIView()
        view.addSubview(panContainer)
        panContainer.anchor(top: nil,
                         leading: view.safeAreaLayoutGuide.leadingAnchor,
                         bottom: nil,
                         trailing: view.safeAreaLayoutGuide.trailingAnchor,
                         padding: .zero,
                         size: CGSize(width: 0, height: 60))
        
        let expiryContainer = UIView()
        view.addSubview(expiryContainer)
        expiryContainer.anchor(top: nil,
                            leading: view.safeAreaLayoutGuide.leadingAnchor,
                            bottom: nil,
                            trailing: view.safeAreaLayoutGuide.trailingAnchor,
                            padding: .zero,
                            size: CGSize(width: 0, height: 60))
        
        
        add(panInputVC, inside: panContainer)
        add(expiryVC, inside: expiryContainer)
        
        let vStack = UIStackView(arrangedSubviews: [panContainer, expiryContainer])
        
        panInputVC.didMove(toParent: self)
        expiryVC.didMove(toParent: self)
        
        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        vStack.isLayoutMarginsRelativeArrangement = true
        
        view.addSubview(vStack)
        vStack.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                      leading: view.safeAreaLayoutGuide.leadingAnchor,
                      bottom: nil,
                      trailing: view.safeAreaLayoutGuide.trailingAnchor,
                      padding: .zero,
                      size: CGSize(width: 0, height: 0))
        
        let stackBackgroundView = UIView()
        stackBackgroundView.backgroundColor = .white
        stackBackgroundView.pinAsBackground(to: vStack)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#EFEFF4")
        self.setupCardInputForm()
    }
}
