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
    let storeFrontDelegate: StoreFrontDelegate
    let purchasedItems: [Product]
    var savedCard: SavedCard?
    var onOrderCreated: ((OrderResponse) -> Void)?

    let apiService = ApiService()

    init(paymentAmount: Double,
         storeFrontDelegate: StoreFrontDelegate,
         with purchasedItems: [Product],
         savedCard: SavedCard? = nil,
         onOrderCreated: @escaping (OrderResponse) -> Void) {
        self.paymentAmount = paymentAmount
        self.storeFrontDelegate = storeFrontDelegate
        self.purchasedItems = purchasedItems
        self.savedCard = savedCard
        self.onOrderCreated = onOrderCreated
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
        var errorTitle = "Unknown Error"
        var errorMessage = ""
        if let error = error {
            let nsError = error as NSError
            let userInfo = nsError.userInfo
            errorTitle = userInfo["NSLocalizedDescription"] as? String
                ?? nsError.localizedDescription
            errorMessage = "Domain: \(nsError.domain), Code: \(nsError.code)"
            print("❌ [Payment] Error displayed: \(errorTitle) | \(errorMessage) | Full error: \(error)")
        }

        DispatchQueue.main.async {
            let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { [weak self] _ in self?.dismissVC() }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func createOrder(savedCard: SavedCard? = nil) {
        print("🔥 [CreateOrder] CALLED - amount: \(paymentAmount)")
        // Multiply amount always by 100 while creating an order
        let merchantAttributes = Environment.getMerchantAttributes()
        let attributeDictionary: [String: String]? = if (merchantAttributes.isEmpty) {
            nil
        } else {
            merchantAttributes.reduce(into: [String: String]()) { dict, attribute in
                dict[attribute.key] = attribute.value
            }
        }
        let currencyCode = Environment.getRegion() == "KSA" ? "SAR" : "AED"
        var orderRequest = OrderRequest(action: Environment.getOrderAction(),
                                        amount: OrderAmount(currencyCode: currencyCode, value: paymentAmount * 100),
                                        language: Environment.getLanguage(),
                                        merchantAttributes: attributeDictionary,
                                        savedCard: savedCard)

        // add required parameters for order type
        let orderType = Environment.getOrderType()
        switch orderType {
            case "INSTALLMENT":
                orderRequest.installmentDetails = InstallmentDetails(numberOfTenure: 2)
                orderRequest.type = "INSTALLMENT"
                orderRequest.frequency = "MONTHLY"
            case "UNSCHEDULED":
                orderRequest.type = "UNSCHEDULED"
            case "RECURRING":
                orderRequest.type = "RECURRING"
                orderRequest.frequency = "MONTHLY"
                orderRequest.recurringDetails = RecurringDetails(numberOfTenure: 10, recurringType: "FIXED")
            default:
                break
        }
        
        apiService.createOrder(orderData: orderRequest) { result in
            switch result {
            case .success(let orderResponse):
                self.storeFrontDelegate.updateOrderId(orderId: orderResponse.reference ?? "")
                NISdk.sharedInstance.setSDKLanguage(language: Environment.getLanguage())
                DispatchQueue.main.async {
                    self.dismiss(animated: false, completion: { [weak self] in
                        self?.onOrderCreated?(orderResponse)
                    })
                }
            case .failure(let error):
                self.displayErrorAndClose(error: error)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔥 [OrderCreationVC] viewDidLoad called")
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
