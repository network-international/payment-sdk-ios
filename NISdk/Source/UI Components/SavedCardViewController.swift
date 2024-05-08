//
//  SavedCardViewController.swift
//  NISdk
//
//  Created by Gautam Chibde on 13/10/23.
//  Copyright © 2023 Network International. All rights reserved.
//

import UIKit

class SavedCardViewController: UIViewController, UITextFieldDelegate {
    // data properties
    let cvv = Cvv()
    let onCancel: () -> Void?
    
    // ui properties
    let scrollView = UIScrollView()
    let contentView = UIView()
    let orderAmount: Amount
    var allowedCardProviders: [CardProvider]?
    let payButton: UIButton = {
        let payButton = UIButton()
        payButton.backgroundColor = NISdk.sharedInstance.niSdkColors.payButtonBackgroundColor
        payButton.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonTitleColor, for: .normal)
        payButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        payButton.setTitleColor(NISdk.sharedInstance.niSdkColors.payButtonTitleColorHighlighted, for: .highlighted)
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
            self.cvvTextField.isEnabled = false
            self.payButton.isEnabled = self.paymentInProgress
            if(self.paymentInProgress) {
                self.loadingSpinner.startAnimating()
                self.payButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
            } else {
                self.loadingSpinner.stopAnimating()
                self.payButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            }
        }
    }
    
    let cardPreviewContainer = UIView()
    let loadingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .gray
        spinner.isHidden = true
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    var makeSaveCardPaymentCallback: MakeSaveCardPaymentCallback
    var cardPreviewController = CardPreviewController()
    let savedCard: SavedCard
    
    let cvvTextField: UITextField = UITextField()
    
    required init(makeSaveCardPaymentCallback: @escaping MakeSaveCardPaymentCallback,
                  savedCard: SavedCard,
                  orderAmount: Amount,
                  onCancel: @escaping () -> Void) {
        self.makeSaveCardPaymentCallback = makeSaveCardPaymentCallback
        self.onCancel = onCancel
        self.savedCard = savedCard
        self.orderAmount = orderAmount
        if (savedCard.scheme == "AMERICAN_EXPRESS") {
            self.cvv.length = CVVLengths.amex
        } else {
            self.cvv.length = CVVLengths.normal
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
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
        let textAttributes = [NSAttributedString.Key.foregroundColor: NISdk.sharedInstance.niSdkColors.payPageTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
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
        cardPreviewController.setSavedCard(savedCard: savedCard)
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
                      padding:  UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0),
                      size: CGSize(width: 0, height: 0))
        vStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        vStack.isLayoutMarginsRelativeArrangement = true
        
        let stackBackgroundView = UIView()
        stackBackgroundView.backgroundColor = NISdk.sharedInstance.niSdkColors.payPageBackgroundColor
        stackBackgroundView.addBorder(.top, color: NISdk.sharedInstance.niSdkColors.payPageDividerColor , thickness: 1)
        stackBackgroundView.addBorder(.bottom, color: NISdk.sharedInstance.niSdkColors.payPageDividerColor , thickness: 1)
        stackBackgroundView.pinAsBackground(to: vStack)

        // Setup CVV field
        let cvvInputVC = CvvInputVC(onChangeText: onChangeCVV, cvv: self.cvv)
        let cvvContainer = UIView()
        vStack.addArrangedSubview(cvvContainer)
        cvvContainer.anchor(heightConstant: 60)
        add(cvvInputVC, inside: cvvContainer)
        cvvInputVC.didMove(toParent: self)
        
        let errorContainer = UIView()
        contentView.addSubview(errorContainer)
        errorContainer.anchor(top: vStack.bottomAnchor,
                              leading: contentView.leadingAnchor,
                              bottom: nil,
                              trailing: contentView.trailingAnchor,
                              padding: UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30),
                              size: CGSize(width: 0, height: 32))
        errorContainer.addSubview(errorLabel)
        errorLabel.alignCenterToCenterOf(parent: errorContainer)

        payButton.addTarget(self, action: #selector(payButtonAction), for: .touchUpInside)
        let payButtonTitle: String = if NISdk.sharedInstance.shouldShowOrderAmount {
            String.localizedStringWithFormat("Pay Button Title".localized, orderAmount.getFormattedAmount())
        } else {
            "Pay".localized
        }
        self.payButton.setTitle(payButtonTitle, for: .normal)
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
    
    @objc lazy private var onChangeCVV: onChangeTextClosure = { [weak self] textField in
        self?.cvv.value = textField.text ?? ""
    }
    
    func validateAllFields() -> (Bool, [String:String]) {
        var errors: [String:String] = [:]
        
        let isCvvValid = cvv.validate()
        if(!isCvvValid) {
            errors["cvv"] = "Invalid CVV Field".localized
        }
        
        return (errors.isEmpty, errors)
    }
    
    @objc func payButtonAction() {
        let (isAllValid, errors) = validateAllFields()
        if let cvv = cvv.value {
            if (isAllValid) {
                errorLabel.text = ""
                let savedCardRequest = SavedCardRequest(
                    expiry: savedCard.expiry,
                    cardholderName: savedCard.cardholderName,
                    cardToken: savedCard.cardToken,
                    cvv: cvv)
                paymentInProgress = true
                updateCancelButtonWith(status: false)
                makeSaveCardPaymentCallback(savedCardRequest)
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
