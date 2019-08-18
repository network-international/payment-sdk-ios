//
//  NITransaction.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

/* protocol conforming to transaction service */
@objc public protocol Transaction {
    @objc func makePayment(for order: NIOrder, with paymentToken: String)
}
