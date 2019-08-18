//
//  NITransactionAdapter.swift
//  NISdk
//
//  Created by Johnny Peter on 09/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

let domain = "https://api-gateway-dev.ngenius-payments.com/"

import Foundation

@objc public final class TransactionServiceAdapter: NSObject, TransactionService {
    public func authorisePayment(for authCode: String) {
        // _links.payment-authorization.href
        let url = "\(domain)/transactions/paymentAuthorization"
        
        // Headers :-
        // Accept: application/vnd.ni-payment.v2+json
        // Media-Type: application/x-www-form-urlencoded
        // Content-Type: application/x-www-form-urlencoded
        
        // Body (form url encoded)
        // code=authCode
        
        // for auth code
        // _links.payment.href
        // "https://paypage-dev.ngenius-payments.com/?code=424d0243dbea8f5d"
        
        // Response headers
        // Set-Cookie.payment-token
    }
    
    public func getOrder(with orderId: String, under outlet: String, using paymentToken: String) {
        // _links.self.href
        // "https://api-gateway-dev.ngenius-payments.com/transactions/outlets/0411acca-92f2-4305-a732-ac0f105d2a40/orders/403eeb5f-9987-4a91-9a18-03ee189f0a08"
    }
    
    public func makePayment(for order: Order, using paymentToken: String) {
        // _links.cnp:payment-link.href
        // "https://api-gateway-dev.ngenius-payments.com/transactions/outlets/0411acca-92f2-4305-a732-ac0f105d2a40/orders/403eeb5f-9987-4a91-9a18-03ee189f0a08/payment-link"
    }
}
