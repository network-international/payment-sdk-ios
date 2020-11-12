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
    let storeFrontDelegate: StoreFrontDelegate
    let paymentMethod: PaymentMethod?
    let purchasedItems: [Product]
    var paymentRequest: PKPaymentRequest?
    
    init(paymentAmount: Double,
         cardPaymentDelegate: CardPaymentDelegate,
         storeFrontDelegate: StoreFrontDelegate,
         using paymentMethod: PaymentMethod = .Card,
         with purchasedItems: [Product]) {
        
        self.cardPaymentDelegate = cardPaymentDelegate
        self.paymentAmount = paymentAmount
        self.paymentMethod = paymentMethod
        self.purchasedItems = purchasedItems
        self.storeFrontDelegate = storeFrontDelegate
        super.init(nibName: nil, bundle: nil)
                
        if(paymentMethod == .ApplePay) {
            let merchantId = ""
            assert(!merchantId.isEmpty, "You need to add your apple pay merchant ID above")
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
    
    func createOrder() {
        // Multiply amount always by 100 while creating an order
        let orderRequest = OrderRequest(action: "SALE",
                                        amount: OrderAmount(currencyCode: "AED", value: paymentAmount * 100))
        let encoder = JSONEncoder()
        let orderRequestData = try! encoder.encode(orderRequest)
        let headers = ["Content-Type": "application/json"]
        let request = NSMutableURLRequest(url: NSURL(string: "http://localhost:3000/api/createOrder")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = orderRequestData

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { [weak self] (data, response, error) in
            if (error != nil) {
                self?.displayErrorAndClose(error: error)
            }
            if let data = data {
                do {
                    let orderResponse: OrderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
                    let sharedSDKInstance = NISdk.sharedInstance
                    DispatchQueue.main.async {
                        self?.dismiss(animated: false, completion: { [weak self] in
                            if(self?.paymentMethod == .Card) {
                                sharedSDKInstance.showCardPaymentViewWith(cardPaymentDelegate: (self?.cardPaymentDelegate!)!,
                                                                          overParent: self?.cardPaymentDelegate as! UIViewController,
                                                                        for: orderResponse)
                            } else {
                                sharedSDKInstance.initiateApplePayWith(applePayDelegate: self?.cardPaymentDelegate as? ApplePayDelegate,
                                                                       cardPaymentDelegate: (self?.cardPaymentDelegate)!,
                                                                       overParent: self?.cardPaymentDelegate as!UIViewController,
                                                                       for: orderResponse, with: self!.paymentRequest!)
                            }
                        })
                    }
                } catch let error {
                    self?.displayErrorAndClose(error: error)
                }
            }
        })
        dataTask.resume()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = .white
        
        let authorizationLabel = UILabel()
        authorizationLabel.textColor = .white
        authorizationLabel.text = "Creating Order..."
        
        let spinner = UIActivityIndicatorView(style: .gray)
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
        
        self.createOrder()
    }
}
