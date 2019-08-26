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
    var makePaymentCallback: MakePaymentCallback?
    let pan = Pan()
    let cvv = Cvv()
    let cardHolderName = CardHolderName()
    let expiryDate = ExpiryDate()
    
    // ui properties
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    let cardPreviewContainer = UIView()
    
    init(makePaymentCallback: MakePaymentCallback?) {
        if let makePaymentCallback = makePaymentCallback {
            self.makePaymentCallback = makePaymentCallback
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#EFEFF4")
        setupScrollView()
        setupCardPreviewComponent()
        setupCardInputForm()
    }
    
    func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                          leading: view.safeAreaLayoutGuide.leadingAnchor,
                          bottom: view.safeAreaLayoutGuide.bottomAnchor,
                          trailing: view.safeAreaLayoutGuide.trailingAnchor)
        scrollView.anchor(width: view.safeAreaLayoutGuide.widthAnchor)
        
        scrollView.addSubview(contentView)
        contentView.anchor(top: scrollView.topAnchor,
                           leading: scrollView.leadingAnchor,
                           bottom: scrollView.bottomAnchor,
                           trailing: scrollView.trailingAnchor)
        contentView.anchor(width: view.widthAnchor)
    }
    
    func setupCardPreviewComponent() {
        let cardPreviewController = CardPreviewController()
        contentView.addSubview(cardPreviewContainer)
        cardPreviewContainer.anchor(top: contentView.topAnchor, leading: contentView.leadingAnchor, bottom: nil, trailing: contentView.trailingAnchor, padding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30), size: CGSize(width: 0, height: 200))
        
        add(cardPreviewController, inside: cardPreviewContainer)
        cardPreviewController.didMove(toParent: self)
    }

    func setupCardInputForm() {
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 0
        
        contentView.addSubview(vStack)
        vStack.anchor(top: cardPreviewContainer.bottomAnchor,
                      leading: contentView.leadingAnchor,
                      bottom: nil,
                      trailing: contentView.trailingAnchor,
                      padding:  UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0),
                      size: CGSize(width: 0, height: 0))
        vStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        vStack.isLayoutMarginsRelativeArrangement = true
        
        let stackBackgroundView = UIView()
        stackBackgroundView.backgroundColor = .white
        stackBackgroundView.addBorder(.top, color: UIColor(hexString: "#dbdbdc") , thickness: 1)
        stackBackgroundView.addBorder(.bottom, color: UIColor(hexString: "#dbdbdc") , thickness: 1)
        stackBackgroundView.pinAsBackground(to: vStack)
        
        // Setup Pan field
        let panInputVC = PanInputVC(onChangeText: onChangePan)
        let panContainer = UIView()
        vStack.addArrangedSubview(panContainer)
        panContainer.anchor(heightConstant: 60)
        add(panInputVC, inside: panContainer)
        panInputVC.didMove(toParent: self)

        // Setup Expiry field
        let expiryInputVC = ExpiryInputVC(onChangeMonth: onChangeMonth, onChangeYear: onChangeYear)
        let expiryContainer = UIView()
        vStack.addArrangedSubview(expiryContainer)
        expiryContainer.anchor(heightConstant: 60)
        add(expiryInputVC, inside: expiryContainer)
        expiryInputVC.didMove(toParent: self)


        // Setup CVV field
        let cvvInputVC = CvvInputVC(onChangeText: onChangeCVV)
        let cvvContainer = UIView()
        vStack.addArrangedSubview(cvvContainer)
        cvvContainer.anchor(heightConstant: 60)
        add(cvvInputVC, inside: cvvContainer)
        cvvInputVC.didMove(toParent: self)

        // Setup Name field
        let nameInputVC = NameInputVC(onChangeText: onChangeName)
        let nameContainer = UIView()
        vStack.addArrangedSubview(nameContainer)
        nameContainer.anchor(heightConstant: 60)
        add(nameInputVC, inside: nameContainer)
        nameInputVC.didMove(toParent: self)

        let payButton = UIButton()
        payButton.backgroundColor = .black
        payButton.setTitleColor(.white, for: .normal)
        payButton.setTitle("Pay", for: .normal)
        payButton.addTarget(self, action: #selector(payButtonAction), for: .touchUpInside)

        contentView.addSubview(payButton)
        payButton.anchor(top: vStack.bottomAnchor,
                         leading: contentView.leadingAnchor,
                         bottom: contentView.bottomAnchor,
                         trailing: contentView.trailingAnchor,
                         padding: UIEdgeInsets(top: 50, left: 20, bottom: 20, right: 20),
                         size: CGSize(width: 0, height: 50))
    }
    
    @objc lazy private var onChangePan: onChangeTextClosure = { [weak self] textField in
        self?.pan.value = textField.text ?? ""
    }
    
    @objc lazy private var onChangeMonth: onChangeTextClosure = { [weak self] textField in
        self?.expiryDate.month = textField.text ?? ""
    }
    
    @objc lazy private var onChangeYear: onChangeTextClosure = { [weak self] textField in
        self?.expiryDate.year = textField.text ?? ""
    }
    
    @objc lazy private var onChangeCVV: onChangeTextClosure = { [weak self] textField in
        self?.cvv.value = textField.text ?? ""
    }
    
    @objc lazy private var onChangeName: onChangeTextClosure = { [weak self] textField in
        self?.cardHolderName.value = textField.text ?? ""
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
            makePaymentCallback?(paymentRequest)
        }
    }
}
