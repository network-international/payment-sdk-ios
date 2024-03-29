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

class StoreFrontViewController:
    UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDelegate,
    CardPaymentDelegate,
    StoreFrontDelegate,
    ApplePayDelegate,
    CreditCardInfoViewDelegate {
    
    var collectionView: UICollectionView?
    
    var bottomConstraintCardInfoView: NSLayoutConstraint? = nil
    let payButton = UIButton()
    var orderId: String?
    lazy var applePayButton = PKPaymentButton(paymentButtonType: .buy , paymentButtonStyle: .black)
    let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 20
        return stack
    }()
    
    let cardInfoView = CreditCardInfoView()
    let pets = ["🐊", "🐅", "🐆", "🦓", "🦏", "🦠", "🐙", "🐡", "🐋", "🐳"]
    var total: Double = 0 {
        didSet { showHidePayButtonStack() }
    }
    var selectedItems: [Product] = []
    var paymentRequest: PKPaymentRequest?
    
    var savedCard: SavedCard? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        setupPaymentButtons()
        setupCardInfoView()
        
        title = "Zoomoji Store"
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
        view.addSubview(collectionView!)
        
        guard let data = UserDefaults.standard.data(forKey: "SavedCard") else {
            return
        }
        do {
            self.savedCard = try JSONDecoder().decode(SavedCard.self, from: data)
        } catch _ {
            print("error getting saved card")
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            bottomConstraintCardInfoView?.constant = -(keyboardSize.height - 60)
            print(keyboardSize.height)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        bottomConstraintCardInfoView?.constant = -16
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
    
    @objc func paymentDidComplete(with status: PaymentStatus) {
        if(status == .PaymentSuccess) {
            resetSelection()
            showAlertWith(title: "Payment Successfull", message: "Your Payment was successfull.")
            getSavedCard()
            return
        } else if(status == .PaymentFailed) {
            showAlertWith(title: "Payment Failed", message: "Your Payment could not be completed.")
        } else if(status == .PaymentCancelled) {
            showAlertWith(title: "Payment Aborted", message: "You cancelled the payment request. You can try again!")
        } else if (status == .PaymentPostAuthReview) {
            showAlertWith(title: "Payment In Auth Review", message: "Payment is in review will need to be approved via portal")
        }
    }
    
    @objc func authorizationDidComplete(with status: AuthorizationStatus) {
        if(status == .AuthFailed) {
            print("Auth Failed :(")
            return
        }
        print("Auth Passed :)")
    }
    
    private func getSavedCard() {
        if let orderId = self.orderId {
            
            let baseUrl = "http://localhost:3000/order/\(orderId)"
            let url = URL(string: baseUrl)!
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    let orderResponse: OrderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
                    if let savedCard = orderResponse.embeddedData?.payment?.first?.savedCard {
                        let json = try JSONEncoder().encode(savedCard)
                        self.savedCard = savedCard
                        UserDefaults.standard.set(json, forKey: "SavedCard")
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }
            task.resume()
        }
    }
    
    @objc func didSelectPaymentMethod(paymentMethod: PKPaymentMethod) -> PKPaymentRequestPaymentMethodUpdate {
        if let paymentRequest = self.paymentRequest {
            return PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: paymentRequest.paymentSummaryItems)
        }
        let summaryItem = [PKPaymentSummaryItem(label: "NGenius merchant", amount: NSDecimalNumber(value: 0))]
        return PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: summaryItem)
    }
    
    @objc func payButtonTapped() {
        let orderCreationViewController = OrderCreationViewController(paymentAmount: total, cardPaymentDelegate: self, storeFrontDelegate: self, using: .Card, with: selectedItems)
        orderCreationViewController.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        orderCreationViewController.modalPresentationStyle = .overCurrentContext
        self.present(orderCreationViewController, animated: false, completion: nil)
    }
    
    @objc func applePayButtonTapped(applePayPaymentRequest: PKPaymentRequest) {
        let orderCreationViewController = OrderCreationViewController(paymentAmount: total, cardPaymentDelegate: self, storeFrontDelegate: self, using: .ApplePay, with: selectedItems)
        orderCreationViewController.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        orderCreationViewController.modalPresentationStyle = .overCurrentContext
        self.present(orderCreationViewController, animated: true, completion: nil)
    }
    
    // Used to update the paymentRequest object
    func updatePKPaymentRequestObject(paymentRequest: PKPaymentRequest) {
        self.paymentRequest = paymentRequest
    }
    
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
        
        // Pay button for card
        payButton.backgroundColor = .black
        payButton.setTitleColor(.white, for: .normal)
        payButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        payButton.setTitleColor(UIColor(red: 255, green: 255, blue: 255, alpha: 0.6), for: .highlighted)
        payButton.setTitle("Pay", for: .normal)
        payButton.layer.cornerRadius = 5
        payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(payButton)
        
        // Pay button for Apple Pay
        if(NISdk.sharedInstance.deviceSupportsApplePay()) {
            applePayButton.addTarget(self, action: #selector(applePayButtonTapped), for: .touchUpInside)
            buttonStack.addArrangedSubview(applePayButton)
        }
    }
    
    func setupCardInfoView() {
        navigationController?.view.addSubview(cardInfoView)
        if let parentView = navigationController?.view {
            bottomConstraintCardInfoView = cardInfoView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor)
            cardInfoView.translatesAutoresizingMaskIntoConstraints = false
            bottomConstraintCardInfoView?.isActive = true
            cardInfoView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20).isActive = true
            cardInfoView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 20).isActive = true
            
            cardInfoView.heightAnchor.constraint(equalToConstant: 75).isActive = true
            cardInfoView.isHidden = true
        }
        cardInfoView.delegate = self
    }
    
    func didTapPayButton(withCVV cvv: String?) {
        let orderCreationViewController = OrderCreationViewController(paymentAmount: total, cardPaymentDelegate: self, storeFrontDelegate: self, using: .SavedCard, with: selectedItems, savedCard: self.savedCard, cvv: cvv)
        orderCreationViewController.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        orderCreationViewController.modalPresentationStyle = .overCurrentContext
        self.present(orderCreationViewController, animated: false, completion: nil)
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
            if let savedCard = self.savedCard {
                cardInfoView.setCard(savedCard: savedCard)
                cardInfoView.isHidden = false
            }
            payButton.setTitle("Pay Aed \(total)", for: .normal)
        } else {
            buttonStack.isHidden = true
            cardInfoView.isHidden = true
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
        
        cell.productLabel.text = pets[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenRect = UIScreen.main.bounds
        let screenWidth = screenRect.size.width
        let length = (screenWidth / 2) - 20
        return CGSize(width: length, height: length)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 80, right: 15)
    }
    
    func updateOrderId(orderId: String) {
        self.orderId = orderId
    }
}

protocol StoreFrontDelegate {
    func updatePKPaymentRequestObject(paymentRequest: PKPaymentRequest)
    
    func updateOrderId(orderId: String)
}
