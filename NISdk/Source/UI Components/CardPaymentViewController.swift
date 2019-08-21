//
//  CardView.swift
//  NISdk
//
//  Created by Johnny Peter on 15/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import UIKit

typealias onChangeTextClosure = (UITextField) -> Void

class CardPaymentViewController: UIViewController {
    // data properties
    var makePaymentCallback: MakePaymentCallback
    let pan = Pan()
    let cvv = Cvv()
    let cardHolderName = CardHolderName()
    let expiryDate = ExpiryDate()
    
    // ui properties
    let cardPreviewContainer = UIView()
    let cardPreviewController = CardPreviewController()
    
    init(makePaymentCallback: @escaping MakePaymentCallback) {
        self.makePaymentCallback = makePaymentCallback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#EFEFF4")
        self.setupCardPreviewComponent()
        self.setupCardInputForm()
    }
    
    @objc func onChangePan(textField: UITextField) {
        pan.value = textField.text ?? ""
    }
    
    @objc func onChangeMonth(textField: UITextField) {
        expiryDate.month = textField.text ?? ""
    }
    
    @objc func onChangeYear(textField: UITextField) {
        expiryDate.year = textField.text ?? ""
    }
    
    @objc func onChangeCVV(textField: UITextField) {
        cvv.value = textField.text ?? ""
    }
    
    @objc func onChangeName(textField: UITextField) {
        cardHolderName.value = textField.text ?? ""
    }
    
    @objc func payButtonAction() {
        if let pan = pan.value,
            let expiryMonth = expiryDate.month,
            let expiryYear = expiryDate.year,
            let cvv = cvv.value,
            let cardHolderName = cardHolderName.value {
            let paymentRequest = PaymentRequest(pan: pan,
                                                expiryMonth: expiryMonth,
                                                expiryYear: expiryYear,
                                                cvv: cvv,
                                                cardHolderName: cardHolderName)
            makePaymentCallback(paymentRequest)
        }
    }
    
    func setupCardPreviewComponent() {
        view.addSubview(cardPreviewContainer)
        cardPreviewContainer.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                                    leading: view.safeAreaLayoutGuide.leadingAnchor,
                                    bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor,
                                    padding: UIEdgeInsets(top: 30, left: 40, bottom: 30, right: 40),
                                    size: CGSize(width: 0, height: 200))
        add(cardPreviewController, inside: cardPreviewContainer)
        cardPreviewController.didMove(toParent: self)
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
        vStack.anchor(top: cardPreviewContainer.bottomAnchor,
                      leading: view.safeAreaLayoutGuide.leadingAnchor,
                      bottom: nil,
                      trailing: view.safeAreaLayoutGuide.trailingAnchor,
                      padding:  UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0),
                      size: CGSize(width: 0, height: 0))
        
        let stackBackgroundView = UIView()
        stackBackgroundView.backgroundColor = .white
        stackBackgroundView.addBorder(.top, color: UIColor(hexString: "#dbdbdc") , thickness: 1)
        stackBackgroundView.addBorder(.bottom, color: UIColor(hexString: "#dbdbdc") , thickness: 1)
        stackBackgroundView.pinAsBackground(to: vStack)
        
        let payButton = UIButton()
        payButton.backgroundColor = .black
        payButton.setTitleColor(.white, for: .normal)
        payButton.setTitle("Pay", for: .normal)
        payButton.addTarget(self, action: #selector(payButtonAction), for: .touchUpInside)
        
        view.addSubview(payButton)
        payButton.anchor(top: vStack.bottomAnchor,
                         leading: view.safeAreaLayoutGuide.leadingAnchor,
                         bottom: nil,
                         trailing: view.safeAreaLayoutGuide.trailingAnchor,
                         padding: UIEdgeInsets(top: 50, left: 20, bottom: 20, right: 20),
                         size: CGSize(width: 0, height: 50))
    }
}
