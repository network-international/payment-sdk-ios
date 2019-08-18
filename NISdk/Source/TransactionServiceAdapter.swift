//
//  NITransactionAdapter.swift
//  NISdk
//
//  Created by Johnny Peter on 09/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc public final class TransactionServiceAdapter: NSObject, TransactionService {
    public func authorisePayment(for authCode: String) {
        
    }
    
    public func getOrder(with orderId: String, under outlet: String, using paymentToken: String) {
        
    }
    
    public func makePayment(for order: Order, using paymentToken: String) {
        
    }
}
