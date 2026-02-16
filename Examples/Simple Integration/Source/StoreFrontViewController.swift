//
//  StoreFrontViewController.swift
//  Simple Integration
//
//  Created by Johnny Peter on 22/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import UIKit
import NISdk
import PassKit
import SwiftUI

/// Payment SDK Integration Guide
///
/// PREREQUISITES:
///   - Add NISdk via CocoaPods or SPM
///   - Obtain API key and outlet reference from N-Genius portal
///   - For Apple Pay: configure merchant ID in Apple Developer portal
///
/// STEPS:
///   1. Conform to CardPaymentDelegate (and optionally ApplePayDelegate, ClickToPayDelegate)
///   2. Create an order via your backend (see OrderCreationViewController / ApiService)
///   3. Launch payment: NISdk.sharedInstance.showCardPaymentViewWith(...)
///   4. Handle results in paymentDidComplete(with:) delegate method
///
/// OPTIONAL:
///   - Apple Pay: NISdk.sharedInstance.initiateApplePayWith()
///   - Click to Pay: NISdk.sharedInstance.launchClickToPay()
///   - Aani Pay: NISdk.sharedInstance.launchAaniPay()
///   - Saved Cards: NISdk.sharedInstance.launchSavedCardPayment()
///   - SDK Colors: NISdk.sharedInstance.setSDKColors()
///   - Language: NISdk.sharedInstance.setSDKLanguage()
class StoreFrontViewController:
    UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDelegate,
    CardPaymentDelegate,
    StoreFrontDelegate,
    ApplePayDelegate,
    PaymentOptionsDelegate {

    var collectionView: UICollectionView?

    let payButton = UIButton()
    var orderId: String?
    let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }()

    let pets: [Product] = [
        Product(name: "Quick Test", amount: 0.10),
        Product(name: "Micro", amount: 0.50),
        Product(name: "Small", amount: 1),
        Product(name: "Basic", amount: 2),
        Product(name: "Standard", amount: 5),
        Product(name: "Medium", amount: 10),
        Product(name: "Large", amount: 50),
        Product(name: "Premium", amount: 100),
        Product(name: "Pro", amount: 450),
        Product(name: "Business", amount: 1000),
        Product(name: "Enterprise", amount: 2200),
        Product(name: "Ultimate", amount: 3000),
    ]
    var total: Double = 0 {
        didSet { showHidePayButtonStack() }
    }
    var selectedItems: [Product] = []
    var paymentRequest: PKPaymentRequest?

    var savedCard: SavedCard? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPaymentButtons()

        let logoImageView = UIImageView()
        if let logoImage = UIImage(named: "networklogo", in: Bundle(for: NISdk.self), compatibleWith: nil) {
            logoImageView.image = logoImage
        }
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        logoImageView.widthAnchor.constraint(equalToConstant: 140).isActive = true

        let demoLabel = UILabel()
        demoLabel.text = "Demo"
        demoLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        demoLabel.textColor = .secondaryLabel
        demoLabel.textAlignment = .center

        let titleStack = UIStackView(arrangedSubviews: [logoImageView, demoLabel])
        titleStack.axis = .vertical
        titleStack.alignment = .center
        titleStack.spacing = 2
        navigationItem.titleView = titleStack

        self.collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView?.register(ProductViewCell.self, forCellWithReuseIdentifier: "collectionCell")
        collectionView?.delegate = self
        collectionView?.allowsSelection = true
        collectionView?.allowsMultipleSelection = true
        collectionView?.dataSource = self
        collectionView?.backgroundColor = UIColor.white
        if #available(iOS 13, *) {
            collectionView?.backgroundColor = UIColor.systemBackground
        }

        let gearIcon = UIImage(systemName: "gearshape.fill")
        let gearButton = UIButton(type: .custom)
        gearButton.setImage(gearIcon, for: .normal)
        gearButton.addTarget(self, action: #selector(environmentSetup), for: .touchUpInside)
        gearButton.frame = CGRect(x: 0, y: 0, width: 35, height: 35)

        let infoIcon = UIImage(systemName: "info.circle.fill")
        let infoButton = UIButton(type: .custom)
        infoButton.setImage(infoIcon, for: .normal)
        infoButton.addTarget(self, action: #selector(showWhatYouNeed), for: .touchUpInside)
        infoButton.frame = CGRect(x: 0, y: 0, width: 35, height: 35)

        view.addSubview(collectionView!)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: gearButton)
        guard let data = UserDefaults.standard.data(forKey: "SavedCard") else {
            return
        }
        do {
            self.savedCard = try JSONDecoder().decode(SavedCard.self, from: data)
        } catch _ {
            print("error getting saved card")
        }
    }

    @objc func environmentSetup() {
        let environmentViewModel = EnvironmentViewModel()
        let environmentView = EnvironmentView(viewModel: environmentViewModel)

        let navigationController = UINavigationController(rootViewController: UIHostingController(rootView: environmentView))

        navigationController.topViewController?.navigationItem.title = "Configuration"
        navigationController.topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(cancelButtonTapped))

        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: false, completion: nil)
    }

    @objc func showWhatYouNeed() {
        let whatYouNeedView = WhatYouNeedView()

        let navigationController = UINavigationController(rootViewController: UIHostingController(rootView: whatYouNeedView))

        navigationController.topViewController?.navigationItem.title = "What You Need"
        navigationController.topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(cancelButtonTapped))

        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: false, completion: nil)
    }

    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    func resetSelection() {
        total = 0
        selectedItems = []
        collectionView?.deselectAllItems(animated: true, resetHandler: {
            cell in
            if let cell = cell as! ProductViewCell? {
                cell.updateBorder(selected: false)
            }
        })
        self.view.endEditing(true)
    }

    func showAlertWith(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - CardPaymentDelegate (Step 4: Handle payment results)

    @objc func paymentDidComplete(with status: PaymentStatus) {
        switch status {
        case .PaymentSuccess:
            resetSelection()
            showAlertWith(title: "Payment Successfull", message: "Your Payment was successfull.")
            getSavedCard()
        case .PaymentFailed:
            showAlertWith(title: "Payment Failed", message: "Your Payment could not be completed.")
        case .PaymentCancelled:
            showAlertWith(title: "Payment Aborted", message: "You cancelled the payment request. You can try again!")
        case .InValidRequest:
            showAlertWith(title: "Error", message: "Something went wrong")
        case .PaymentPostAuthReview:
            showAlertWith(title: "Payment In Auth Review", message: "Payment is in review will need to be approved via portal")
        case .PartialAuthDeclined:
            showAlertWith(title: "Partial Auth Declined", message: "Customer declined partial auth")
        case .PartialAuthDeclineFailed:
            showAlertWith(title: "Sorry, your payment has not been accepted.", message: "Due to technical error, the refund was not processed. Please contact merchant for refund.")
        case .PartiallyAuthorised:
            showAlertWith(title: "Payment Partially Authorized", message: "Payment Partially Authorized")
        }
    }

    @objc func authorizationDidComplete(with status: AuthorizationStatus) {
        if(status == .AuthFailed) {
            return
        }
    }

    private func getSavedCard() {
        if let orderId = self.orderId {
            ApiService().saveCardForOrder(orderId: orderId) { result in
                switch result {
                case .success(let savedCard):
                    do {
                        let json = try JSONEncoder().encode(savedCard)
                        self.savedCard = savedCard
                        UserDefaults.standard.set(json, forKey: "SavedCard")
                    } catch {
                        print("Error parsing JSON: \(error)")
                    }
                case .failure(let error):
                    print("Error saving card: \(error)")
                }
            }
        }
    }

    @objc func didSelectPaymentMethod(paymentMethod: PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate {
        if let paymentRequest = self.paymentRequest {
            return PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: paymentRequest.paymentSummaryItems)
        }
        let summaryItem = [PKPaymentSummaryItem(label: "NGenius merchant", amount: NSDecimalNumber(value: 0))]
        return PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: summaryItem)
    }

    // MARK: - Pay Button

    @objc func payButtonTapped() {
        guard !Environment.getEnvironments().isEmpty else {
            showAlertWith(title: "Environment Not Configured", message: "You will need to create an environment before you create an order")
            return
        }

        let orderCreationViewController = OrderCreationViewController(
            paymentAmount: total,
            storeFrontDelegate: self,
            with: selectedItems,
            savedCard: savedCard,
            onOrderCreated: { [weak self] orderResponse in
                self?.showPaymentOptions(for: orderResponse)
            }
        )
        orderCreationViewController.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        orderCreationViewController.modalPresentationStyle = .overCurrentContext
        self.present(orderCreationViewController, animated: false, completion: nil)
    }

    // MARK: - SDK Colors

    private func colorFromHex(_ hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized = String(hexSanitized.dropFirst())
        }
        guard hexSanitized.count == 6, let rgbValue = UInt64(hexSanitized, radix: 16) else {
            return nil
        }
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }

    private func applySDKColors() {
        let colors = NISdkColors()

        if let c = colorFromHex(Environment.sdkColorPayButton) { colors.payButtonBackgroundColor = c }
        if let c = colorFromHex(Environment.sdkColorPayButtonText) { colors.payButtonTitleColor = c }
        if let c = colorFromHex(Environment.sdkColorPayButtonDisabled) { colors.payButtonDisabledBackgroundColor = c }
        if let c = colorFromHex(Environment.sdkColorPayButtonDisabledText) { colors.payButtonDisabledTitleColor = c }

        NISdk.sharedInstance.setSDKColors(sdkColors: colors)
    }

    // MARK: - Payment Helpers

    private func makeApplePayRequest() -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = ""
        request.countryCode = Environment.getRegion() == "KSA" ? "SA" : "AE"
        request.currencyCode = Environment.getRegion() == "KSA" ? "SAR" : "AED"
        request.requiredShippingContactFields = [.postalAddress, .emailAddress, .phoneNumber]
        request.merchantCapabilities = [.capabilityDebit, .capabilityCredit, .capability3DS]
        request.requiredBillingContactFields = [.postalAddress, .name]
        request.paymentSummaryItems = selectedItems.map { PKPaymentSummaryItem(label: $0.name, amount: NSDecimalNumber(value: $0.amount)) }
        request.paymentSummaryItems.append(PKPaymentSummaryItem(label: "NGenius merchant", amount: NSDecimalNumber(value: total)))
        return request
    }

    private func makeClickToPayConfig() -> ClickToPayConfig {
        return ClickToPayConfig(
            dpaId: "6BDAU1LI2WBPBQR665ED212rYO7vsj9wje83XQxlwzACNikj8",
            dpaClientId: "10c4cb74-3493-4515-ab72-2b303f790241",
            cardBrands: ["visa", "mastercard"],
            dpaName: "Demo Merchant",
            isSandbox: true
        )
    }

    // MARK: - Payment Options (Step 3: Launch payment with order response)

    private func showPaymentOptions(for orderResponse: OrderResponse) {
        let applePayRequest = makeApplePayRequest()
        self.paymentRequest = applePayRequest

        applySDKColors()

        NISdk.sharedInstance.showCardPaymentViewWith(
            cardPaymentDelegate: self,
            applePayDelegate: self,
            overParent: self,
            for: orderResponse,
            with: applePayRequest,
            clickToPayConfig: makeClickToPayConfig(),
            aaniBackLink: "demoApp://"
        )
    }

    // MARK: - PaymentOptionsDelegate

    func didSelectCardPayment(orderResponse: OrderResponse) {
        applySDKColors()

        NISdk.sharedInstance.showCardPaymentViewWith(
            cardPaymentDelegate: self,
            applePayDelegate: self,
            overParent: self,
            for: orderResponse,
            with: makeApplePayRequest(),
            clickToPayConfig: makeClickToPayConfig(),
            aaniBackLink: "demoApp://"
        )
    }

    func didSelectAaniPayment(orderResponse: OrderResponse) {
        NISdk.sharedInstance.launchAaniPay(
            aaniPaymentDelegate: self,
            overParent: self,
            orderResponse: orderResponse,
            backLink: "demoApp://"
        )
    }

    func didSelectClickToPay(orderResponse: OrderResponse) {
        NISdk.sharedInstance.launchClickToPay(
            clickToPayDelegate: self,
            overParent: self,
            for: orderResponse,
            with: makeClickToPayConfig()
        )
    }

    func didSelectApplePay(orderResponse: OrderResponse) {
        let applePayRequest = makeApplePayRequest()
        self.paymentRequest = applePayRequest

        NISdk.sharedInstance.initiateApplePayWith(
            applePayDelegate: self,
            cardPaymentDelegate: self,
            overParent: self,
            for: orderResponse,
            with: applePayRequest
        )
    }

    func didSelectSavedCard(orderResponse: OrderResponse, savedCard: SavedCard, cvv: String?) {
        NISdk.sharedInstance.launchSavedCardPayment(
            cardPaymentDelegate: self,
            overParent: self,
            for: orderResponse,
            with: cvv
        )
    }

    func didCancelPaymentOptions() {
        // User cancelled - do nothing, they return to the store
    }

    // MARK: - StoreFrontDelegate

    func updatePKPaymentRequestObject(paymentRequest: PKPaymentRequest) {
        self.paymentRequest = paymentRequest
    }

    func updateOrderId(orderId: String) {
        self.orderId = orderId
    }

    // MARK: - UI Setup

    func setupPaymentButtons() {
        navigationController?.view.addSubview(buttonStack)
        configureButtonStack()
        if let parentView = navigationController?.view {
            buttonStack.translatesAutoresizingMaskIntoConstraints = false
            buttonStack.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 20).isActive = true
            buttonStack.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20).isActive = true
            buttonStack.heightAnchor.constraint(equalToConstant: 50).isActive = true
            buttonStack.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -50).isActive = true
            buttonStack.isHidden = true
        }

        // Single Pay button
        payButton.backgroundColor = UIColor(red: 0.0/255.0, green: 85.0/255.0, blue: 222.0/255.0, alpha: 1.0)
        payButton.setTitleColor(.white, for: .normal)
        payButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        payButton.setTitleColor(UIColor(red: 255, green: 255, blue: 255, alpha: 0.6), for: .highlighted)
        payButton.setTitle("Pay", for: .normal)
        payButton.layer.cornerRadius = 8
        payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(payButton)
    }

    func configureButtonStack() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.pinAsBackground(to: buttonStack)
    }

    func showHidePayButtonStack() {
        if(total > 0) {
            buttonStack.isHidden = false
            let currencyCode = Environment.getRegion() == "KSA" ? "SAR" : "AED"
            payButton.setTitle("Pay \(currencyCode) \(String(format: "%.2f", total))", for: .normal)
        } else {
            buttonStack.isHidden = true
        }
    }

    func add(amount: Double, emoji: String) {
        total += amount
        selectedItems.append(Product(name: emoji, amount: amount))
    }

    func remove(amount: Double, emoji: String) {
        total -= amount
        selectedItems = selectedItems.filter { $0.name != emoji}
    }

    // MARK: - UICollectionView

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! ProductViewCell
        if cell.isSelected {
            cell.updateBorder(selected: true)
        } else {
            cell.updateBorder(selected: false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pets.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ProductViewCell
        cell.isSelected = true
        cell.updateBorder(selected: true)
        add(amount: cell.price, emoji: cell.productLabel.text!)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ProductViewCell
        cell.isSelected = false
        cell.updateBorder(selected: false)
        remove(amount: cell.price, emoji: cell.productLabel.text!)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath as IndexPath) as! ProductViewCell
        cell.setProduct(product: pets[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenRect = UIScreen.main.bounds
        let screenWidth = screenRect.size.width
        let length = (screenWidth / 2) - 20
        return CGSize(width: length, height: (screenWidth / 2.5) - 20)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 80, right: 15)
    }
}

protocol StoreFrontDelegate {
    func updatePKPaymentRequestObject(paymentRequest: PKPaymentRequest)
    func updateOrderId(orderId: String)
}

extension StoreFrontViewController: ClickToPayDelegate {
    @objc func clickToPayDidComplete(with status: ClickToPayStatus) {
        switch status {
        case .success:
            resetSelection()
            showAlertWith(title: "Payment Successfull", message: "Your Payment was successfull.")
            getSavedCard()
        case .failed:
            showAlertWith(title: "Payment Failed", message: "Your Payment could not be completed.")
        case .cancelled:
            showAlertWith(title: "Payment Aborted", message: "You cancelled the payment request. You can try again!")
        case .postAuthReview:
            showAlertWith(title: "Payment In Auth Review", message: "Payment is in review will need to be approved via portal")
        }
    }
}

extension StoreFrontViewController: AaniPaymentDelegate {
    @objc func aaniPaymentCompleted(with status: AaniPaymentStatus) {
        switch status {
        case .success:
            resetSelection()
            showAlertWith(title: "Payment Successfull", message: "Your Payment was successfull.")
        case .failed:
            showAlertWith(title: "Payment Failed", message: "Your Payment could not be completed.")
        case .cancelled:
            showAlertWith(title: "Payment Aborted", message: "You cancelled the payment request. You can try again!")
        case .invalidRequest:
            showAlertWith(title: "Error", message: "InValid Request")
        }
    }
}
