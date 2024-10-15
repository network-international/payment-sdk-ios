//
//  OrderCreationViewController.swift
//  Simple Integration
//
//  Created by Johnny Peter on 23/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import UIKit
import NISdk
import PassKit

class OrderCreationViewController: UIViewController {
    let paymentAmount: Double
    let cardPaymentDelegate: CardPaymentDelegate?
    let aaniPaymentDelegate: AaniPaymentDelegate?
    let storeFrontDelegate: StoreFrontDelegate
    let paymentMethod: PaymentMethod?
    let purchasedItems: [Product]
    var paymentRequest: PKPaymentRequest?
    var savedCard: SavedCard?
    var cvv: String?
    var orderId: String = ""
    
    let apiService = ApiService()
    
    init(paymentAmount: Double,
         cardPaymentDelegate: CardPaymentDelegate,
         aaniPaymentDelegate: AaniPaymentDelegate,
         storeFrontDelegate: StoreFrontDelegate,
         using paymentMethod: PaymentMethod = .Card,
         with purchasedItems: [Product]) {
        
        self.cardPaymentDelegate = cardPaymentDelegate
        self.aaniPaymentDelegate = aaniPaymentDelegate
        self.paymentAmount = paymentAmount
        self.paymentMethod = paymentMethod
        self.purchasedItems = purchasedItems
        self.storeFrontDelegate = storeFrontDelegate
        super.init(nibName: nil, bundle: nil)
                
        if(paymentMethod == .ApplePay) {
            let merchantId = ""
//            assert(!merchantId.isEmpty, "You need to add your apple pay merchant ID above")
            paymentRequest = PKPaymentRequest()
            paymentRequest?.merchantIdentifier = merchantId
            paymentRequest?.countryCode = "AE"
            paymentRequest?.currencyCode = "AED"
            paymentRequest?.requiredShippingContactFields = [.postalAddress, .emailAddress, .phoneNumber]
            paymentRequest?.merchantCapabilities = [.capabilityDebit, .capabilityCredit, .capability3DS]
            paymentRequest?.requiredBillingContactFields = [.postalAddress, .name]
            paymentRequest?.paymentSummaryItems = self.purchasedItems.map { PKPaymentSummaryItem(label: $0.name, amount: NSDecimalNumber(value: $0.amount)) }
            paymentRequest?.paymentSummaryItems.append(PKPaymentSummaryItem(label: "NGenius merchant", amount: NSDecimalNumber(value: paymentAmount)))
            storeFrontDelegate.updatePKPaymentRequestObject(paymentRequest: paymentRequest!)
        }
    }
    
    init(paymentAmount: Double,
         cardPaymentDelegate: CardPaymentDelegate,
         aaniPaymentDelegate: AaniPaymentDelegate,
         storeFrontDelegate: StoreFrontDelegate,
         using paymentMethod: PaymentMethod,
         with purchasedItems: [Product], 
         savedCard: SavedCard?,
         cvv: String?) {
        self.paymentAmount = paymentAmount
        self.storeFrontDelegate = storeFrontDelegate
        self.aaniPaymentDelegate = aaniPaymentDelegate
        self.cardPaymentDelegate = cardPaymentDelegate
        self.paymentMethod = paymentMethod
        self.savedCard = savedCard
        self.purchasedItems = purchasedItems
        self.cvv = cvv
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dismissVC() {
        DispatchQueue.main.async {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func displayErrorAndClose(error: Error?) {
        var errorTitle = ""
        if let error = error {
            let userInfo: [String: Any] = (error as NSError).userInfo
            errorTitle = userInfo["NSLocalizedDescription"] as? String ?? "Unknown Error"
        }
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: errorTitle, message: "", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { [weak self] _ in self?.dismissVC() }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func createOrder(savedCard: SavedCard? = nil) {
        // Multiply amount always by 100 while creating an order
        let merchantAttributes = Environment.getMerchantAttributes()
        let attributeDictionary: [String: String]? = if (merchantAttributes.isEmpty) {
            nil
        } else {
            merchantAttributes.reduce(into: [String: String]()) { dict, attribute in
                dict[attribute.key] = attribute.value
            }
        }
        let orderRequest = OrderRequest(action: Environment.getOrderAction(),
                                        amount: OrderAmount(currencyCode: "AED", value: paymentAmount * 100),
                                        language: Environment.getLanguage(),
                                        merchantAttributes: attributeDictionary,
                                        savedCard: savedCard)
        
        apiService.createOrder(orderData: orderRequest) { result in
            switch result {
            case .success(let orderResponse):
                let sharedSDKInstance = NISdk.sharedInstance
                if (self.paymentMethod == .Card) {
                    self.storeFrontDelegate.updateOrderId(orderId: orderResponse.reference ?? "")
                }
                NISdk.sharedInstance.setSDKLanguage(language: Environment.getLanguage())
                DispatchQueue.main.async {
                    self.dismiss(animated: false, completion: { [weak self] in
                        if(self?.paymentMethod == .Card) {
                            sharedSDKInstance.showCardPaymentViewWith(cardPaymentDelegate: (self?.cardPaymentDelegate!)!,
                                                                      overParent: self?.cardPaymentDelegate as! UIViewController,
                                                                    for: orderResponse)
                        } else if (self?.paymentMethod == .SavedCard) {
                            sharedSDKInstance.launchSavedCardPayment(
                                cardPaymentDelegate: (self?.cardPaymentDelegate!)!,
                                overParent: self?.cardPaymentDelegate as! UIViewController,
                                for: orderResponse,
                                with: self?.cvv
                            )
                        } else if (self?.paymentMethod == .aaniPay) {
                            sharedSDKInstance.launchAaniPay(
                                aaniPaymentDelegate: (self?.aaniPaymentDelegate!)!,
                                overParent: self?.cardPaymentDelegate as! UIViewController,
                                orderResponse: orderResponse,
                                backLink: "demoApp://"
                            )
                        } else {
                            sharedSDKInstance.initiateApplePayWith(applePayDelegate: self?.cardPaymentDelegate as? ApplePayDelegate,
                                                                   cardPaymentDelegate: (self?.cardPaymentDelegate)!,
                                                                   overParent: self?.cardPaymentDelegate as!UIViewController,
                                                                   for: orderResponse, with: self!.paymentRequest!)
                        }
                    })
                }
            case .failure(let error):
                self.displayErrorAndClose(error: error)
            }
        }
    }
    
    func onCompletion(status: AaniPaymentStatus) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = .white
        
        let authorizationLabel = UILabel()
        authorizationLabel.textColor = .white
        authorizationLabel.text = "Creating Order..."
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.isHidden = false
        spinner.color = .white
        spinner.startAnimating()
        
        let vStack = UIStackView(arrangedSubviews: [authorizationLabel, spinner])
        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.alignment = .center
        
        view.addSubview(vStack)
        vStack.anchor(top: nil,
                      leading: view.safeAreaLayoutGuide.leadingAnchor,
                      bottom: nil,
                      trailing: view.safeAreaLayoutGuide.trailingAnchor,
                      padding: .zero,
                      size: CGSize(width: 0, height: 100))
        
        vStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        vStack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.createOrder(savedCard: savedCard)
    }
}

extension Data {
    func toString(encoding: String.Encoding = .utf8) -> String? {
        return String(data: self, encoding: encoding)
    }
}

extension Data {
    
    func printFormatedJSON() {
        if let json = try? JSONSerialization.jsonObject(with: self, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            pringJSONData(jsonData)
        } else {
            assertionFailure("Malformed JSON")
        }
    }
    
    func printJSON() {
        pringJSONData(self)
    }
    
    private func pringJSONData(_ data: Data) {
        print(String(decoding: data, as: UTF8.self))
    }
}
