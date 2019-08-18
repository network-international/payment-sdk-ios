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
    var cvvValue: String?
    var nameValue: String?
    
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
    
    @objc func onChangeCVV(textField: UITextField) {
        self.cvvValue = textField.text
        print(self.cvvValue ?? "")
    }
    
    @objc func onChangeName(textField: UITextField) {
        self.nameValue = textField.text
        print(self.nameValue ?? "")
    }

    func setupCardInputForm() {
        // Setup Pan field
        let panInputVC = PanInputVC(onChangeText: onChangePan)
        let panContainer = UIView()
        view.addSubview(panContainer)
        panContainer.anchor(top: nil,
                         leading: view.safeAreaLayoutGuide.leadingAnchor,
                         bottom: nil,
                         trailing: view.safeAreaLayoutGuide.trailingAnchor,
                         padding: .zero,
                         size: CGSize(width: 0, height: 60))
        add(panInputVC, inside: panContainer)
        panInputVC.didMove(toParent: self)
        
        // Setup Expiry field
        let expiryInputVC = ExpiryInputVC(onChangeMonth: onChangeMonth, onChangeYear: onChangeYear)
        let expiryContainer = UIView()
        view.addSubview(expiryContainer)
        expiryContainer.anchor(top: nil,
                            leading: view.safeAreaLayoutGuide.leadingAnchor,
                            bottom: nil,
                            trailing: view.safeAreaLayoutGuide.trailingAnchor,
                            padding: .zero,
                            size: CGSize(width: 0, height: 60))
        add(expiryInputVC, inside: expiryContainer)
        expiryInputVC.didMove(toParent: self)

        
        // Setup CVV field
        let cvvInputVC = CvvInputVC(onChangeText: onChangeCVV)
        let cvvContainer = UIView()
        view.addSubview(cvvContainer)
        cvvContainer.anchor(top: nil,
                            leading: view.safeAreaLayoutGuide.leadingAnchor,
                            bottom: nil,
                            trailing: view.safeAreaLayoutGuide.trailingAnchor,
                            padding: .zero,
                            size: CGSize(width: 0, height: 60))
        add(cvvInputVC, inside: cvvContainer)
        cvvInputVC.didMove(toParent: self)
        
        // Setup Name field
        let nameInputVC = NameInputVC(onChangeText: onChangeName)
        let nameContainer = UIView()
        view.addSubview(nameContainer)
        nameContainer.anchor(top: nil,
                            leading: view.safeAreaLayoutGuide.leadingAnchor,
                            bottom: nil,
                            trailing: view.safeAreaLayoutGuide.trailingAnchor,
                            padding: .zero,
                            size: CGSize(width: 0, height: 60))
        add(nameInputVC, inside: nameContainer)
        nameInputVC.didMove(toParent: self)
        
        let vStack = UIStackView(arrangedSubviews: [panContainer, expiryContainer, cvvContainer, nameContainer])
        
        
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
        stackBackgroundView.addBorder(.top, color: UIColor(hexString: "#dbdbdc") , thickness: 1)
        stackBackgroundView.addBorder(.bottom, color: UIColor(hexString: "#dbdbdc") , thickness: 1)
        stackBackgroundView.pinAsBackground(to: vStack)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#EFEFF4")
        self.setupCardInputForm()
    }
}
