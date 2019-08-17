//
//  NITransactionAdapter.swift
//  NISdk
//
//  Created by Johnny Peter on 09/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc public final class NITransactionAdapter: NSObject, NITransaction {
    public func getPaymentToken(for authCode: String) {
    
    }
    
    public func makePayment(for order: NIOrder, with paymentToken: String) {
        
    }
}
