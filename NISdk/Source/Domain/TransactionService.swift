//
//  NITransaction.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

/* protocol conforming to transaction service */
@objc public protocol TransactionService {
    @objc func authorisePayment(for authCode: String)
    @objc func getOrder(with orderId: String, under outlet: String, using paymentToken: String)
    @objc func makePayment(for order: Order, using paymentToken: String)
}
