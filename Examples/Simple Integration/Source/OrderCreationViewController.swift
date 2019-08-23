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

class OrderCreationViewController: UIViewController {
    let cancelButton = UIButton(type: .system)
    let paymentAmount: Int
    let cardPaymentDelegate: CardPaymentDelegate?
    
    init(paymentAmount: Int, and cardPaymentDelegate: CardPaymentDelegate) {
        self.cardPaymentDelegate = cardPaymentDelegate
        self.paymentAmount = paymentAmount
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dismissVC(completion: (() -> Void)?) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: { () in
                if let completion = completion {
                    completion()
                }
            })
        }
    }
    
    func displayErrorAndClose(error: Error?) {
        var errorTitle = ""
        if let error = error {
            let userInfo: [String: Any] = (error as NSError).userInfo
            errorTitle = userInfo["NSLocalizedDescription"] as? String ?? "Unknown Error"
        }
        
        self.dismissVC(completion: {() in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: errorTitle, message: "", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                (self.cardPaymentDelegate as! UIViewController).present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func createOrder() {
        let orderRequest = OrderRequest(action: "SALE",
                                        amount: OrderAmount(currencyCode: "AED", value: paymentAmount))
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
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                self.displayErrorAndClose(error: error)
            }
            if let data = data {
                do {
                    let orderResponse: OrderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
                    let sharedSDKInstance = NISdk.sharedInstance
                    DispatchQueue.main.async {
                        self.dismiss(animated: false, completion: {
                            sharedSDKInstance.showCardPaymentViewWith(cardPaymentDelegate: self.cardPaymentDelegate!,
                                                                      overParent: self.cardPaymentDelegate as! UIViewController,
                                                                      for: orderResponse)
                        })
                    }
                } catch let error {
                    self.displayErrorAndClose(error: error)
                }
            }
        })
        dataTask.resume()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let authorizationLabel = UILabel()
        authorizationLabel.text = "Creating Order..."
        
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.isHidden = false
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
