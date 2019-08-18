//
//  ViewController.swift
//  Simple Integration
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import UIKit
import NISdk


class FirstScreen: UIViewController, CardPaymentDelegate {
    let payButton = UIButton()
    var fetchedOrder: NIOrder?
    
    func paymentDidStart() {
        
    }
    
    func paymentDidComplete(with status: String) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPayButton()
        view.backgroundColor = .white
        
        // Fire request to create order
        HTTPClient()
            .with(url: "http://localhost:3000/sampleOrder")
            .makeRequest {
                (data, urlresponse, error) in
                if let data = data {
                    do {
                        let orderResponse: NIOrder = try JSONDecoder().decode(NIOrder.self, from: data)
                        self.fetchedOrder = orderResponse
                        print(orderResponse.type ?? "Not found");
                    } catch let error {
                        print("Error: \(error)")

                    }

                }
        }
    }
    
    func setupPayButton() {
        payButton.backgroundColor = .black
        payButton.setTitleColor(.white, for: .normal)
        payButton.setTitle("Pay", for: .normal)
        payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)

        view.addSubview(payButton)
        setPayButtonConstraints()
    }
    
    func setPayButtonConstraints() {
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        payButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        payButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    @objc func payButtonTapped() {
        let sharedSDKInstance = NISdk.sharedInstance
        if let order = self.fetchedOrder {
            sharedSDKInstance.showCardPaymentView(withDelegate: self, overParent: self, for: order)
        }
    }
}
