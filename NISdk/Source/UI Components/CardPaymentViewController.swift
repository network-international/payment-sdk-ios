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
    let onCancel: () -> Void?
    
    // ui properties
    let scrollView = UIScrollView()
    let contentView = UIView()
    var orderAmount: Amount?
    var allowedCardProviders: [CardProvider]?
    let payButton: UIButton = {
        let payButton = UIButton()
        payButton.backgroundColor = ColorCompatibility.link
        payButton.setTitleColor(.white, for: .normal)
        payButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        payButton.setTitleColor(UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.6), for: .highlighted)
        payButton.layer.cornerRadius = 5
        payButton.setTitle("Processing Payment".localized, for: .disabled)
        return payButton
    }()
    var errorLabel: UILabel = {
        let errorLabel = UILabel()
        errorLabel.textColor = .red
        errorLabel.text = ""
        return errorLabel
    }()
    
    var paymentInProgress: Bool = false {
        didSet {
            if(self.paymentInProgress) {
                self.loadingSpinner.startAnimating()
                self.payButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
                self.payButton.isEnabled = false
            } else {
                self.loadingSpinner.stopAnimating()
                self.payButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
                self.payButton.isEnabled = true
            }
        }
    }
    
    let cardPreviewContainer = UIView()
    let loadingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .white)
        spinner.isHidden = true
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    init(makePaymentCallback: MakePaymentCallback?, order: OrderResponse, onCancel: @escaping () -> Void) {
        if let makePaymentCallback = makePaymentCallback, let orderAmount = order.amount {
            self.makePaymentCallback = makePaymentCallback
            self.allowedCardProviders = order.paymentMethods?.card
            let payButtonTitle: String = String.localizedStringWithFormat("Pay Button Title".localized, orderAmount.getFormattedAmount())
            self.payButton.setTitle(payButtonTitle, for: .normal)
        }
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorCompatibility.systemBackground
        setupScrollView()
        setupCardPreviewComponent()
        setupCardInputForm()
        setupCancelButton()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tearDownCancelButton()
    }
    
    private func setupCancelButton() {
        self.parent?.navigationController?.setNavigationBarHidden(false, animated: false)
        self.parent?.navigationItem.title = "Make Payment".localized
        self.parent?.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Cancel".localized, style: .done, target: self, action: #selector(self.cancelAction))
    }
    
    private func updateCancelButtonWith(status: Bool) {
        self.parent?.navigationItem.rightBarButtonItem?.isEnabled = status
    }
    
    private func tearDownCancelButton() {
        self.parent?.navigationController?.setNavigationBarHidden(true, animated: true)
        self.parent?.navigationItem.title = nil
        self.parent?.navigationItem.rightBarButtonItem = nil
    }
    
    @objc func cancelAction() {
        self.onCancel();
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardFrame = keyboardSize.cgRectValue
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if(self.scrollView.contentInset.bottom != 0) {
            self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.keyboardDismissMode = .interactive
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
        cardPreviewContainer.anchor(top: contentView.topAnchor,
                                    leading: contentView.leadingAnchor,
                                    bottom: nil, trailing: contentView.trailingAnchor,
                                    padding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30),
                                    size: CGSize(width: 0, height: 200))
        
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
        let stackLayoutDirection = vStack.getUILayoutDirection()
        vStack.layoutMargins = stackLayoutDirection == .leftToRight
            ? UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            : UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        vStack.isLayoutMarginsRelativeArrangement = true
        
        let stackBackgroundView = UIView()
        stackBackgroundView.backgroundColor = ColorCompatibility.systemBackground
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
        let cvvInputVC = CvvInputVC(onChangeText: onChangeCVV, cvv: self.cvv)
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
        
        let errorContainer = UIView()
        contentView.addSubview(errorContainer)
        errorContainer.anchor(top: vStack.bottomAnchor,
                              leading: contentView.leadingAnchor,
                              bottom: nil,
                              trailing: contentView.trailingAnchor,
                              padding: UIEdgeInsets(top: 20, left: 30, bottom: 0, right: 30),
                              size: CGSize(width: 0, height: 50))
        errorContainer.addSubview(errorLabel)
        errorLabel.alignCenterToCenterOf(parent: errorContainer)

        payButton.addTarget(self, action: #selector(payButtonAction), for: .touchUpInside)

        contentView.addSubview(payButton)
        payButton.contentHorizontalAlignment = .center
        payButton.anchor(top: errorContainer.bottomAnchor,
                         leading: contentView.leadingAnchor,
                         bottom: contentView.bottomAnchor,
                         trailing: contentView.trailingAnchor,
                         padding: UIEdgeInsets(top: 20, left: 30, bottom: 0, right: 30),
                         size: CGSize(width: 0, height: 50))
        
        payButton.addSubview(loadingSpinner)
        let payButtonLabel = payButton.titleLabel
        loadingSpinner.anchor(top: payButtonLabel?.topAnchor,
                              leading: payButtonLabel?.trailingAnchor,
                              bottom: nil, trailing: nil,
                              padding: UIEdgeInsets(top: 3, left: 10, bottom: 0, right: 0))
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
    
    func validateAllFields() -> (Bool, [String:String]) {
        var errors: [String:String] = [:]
        
        let isPanValid = pan.validate()
        if(!isPanValid) {
            errors["pan"] = "Invalid pan number".localized
        }
        
        if let allowedCardProviders = allowedCardProviders {
            let panProvider = pan.getCardProvider()
            let allowedCardProvidersSet: Set<CardProvider> = Set(allowedCardProviders)
            if(panProvider != .unknown && !allowedCardProvidersSet.contains(panProvider)) {
                errors["card-provider"] = "Invalid card provider".localized
            }
        }
        
        let isExpiryValid = expiryDate.validate()
        if(!isExpiryValid) {
            errors["expiryDate"] = "Invalid expiry date".localized
        }
        
        let isCvvValid = cvv.validate()
        if(!isCvvValid) {
            errors["cvv"] = "Invalid CVV Field".localized
        }
        
        let isNameValid = cardHolderName.validate()
        if(!isNameValid) {
            errors["cardHolderName"] = "Invalid card holder name".localized
        }
        
        return (errors.isEmpty, errors)
    }
    
    @objc func payButtonAction() {
        let (isAllValid, errors) = validateAllFields()
        if let pan = pan.value,
            let expiryMonth = expiryDate.month,
            let expiryYear = expiryDate.year,
            let cvv = cvv.value,
            let cardHolderName = cardHolderName.value {
            if (isAllValid) {
                errorLabel.text = ""
                let paymentRequest = PaymentRequest(pan: pan,
                                                    expiryMonth: expiryMonth,
                                                    expiryYear: expiryYear,
                                                    cvv: cvv,
                                                    cardHolderName: cardHolderName)
                paymentInProgress = true
                updateCancelButtonWith(status: false)
                makePaymentCallback?(paymentRequest)
                return
            } else {
                if(errors.count == 1) {
                    errorLabel.text = errors.values.first
                    return
                }
            }
        }
        errorLabel.text = "All fields are mandatory".localized
    }
}
