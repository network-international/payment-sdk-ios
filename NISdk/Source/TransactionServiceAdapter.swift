//
//  NITransactionAdapter.swift
//  NISdk
//
//  Created by Johnny Peter on 09/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

@objc final class TransactionServiceAdapter: NSObject, TransactionService {
    
    // Use this to fetch token
    func authorizePayment(for authCode: String,
                                 using authorizationLink: String,
                                 on completion: @escaping (String?) -> Void) {
        
        let authorizationRequestHeaders = ["Accept":"application/vnd.ni-payment.v2+json",
                                           "Media-Type": "application/x-www-form-urlencoded",
                                           "Content-Type": "application/x-www-form-urlencoded"]
        HTTPClient(url: authorizationLink)?
            .withMethod(method: "POST")
            .withHeaders(headers: authorizationRequestHeaders)
            .withBodyData(data: "code=\(authCode)")
            .makeRequest(with: { (Data, URLResponse, Error) in
                if let httpURLResponse = URLResponse as? HTTPURLResponse {
                    let headers = httpURLResponse.allHeaderFields
                    let paymentTokenHeader = headers.filter {
                        if let headerValue = $0.value as? String {
                            return headerValue.contains("payment-token")
                        }
                        return false
                    }
                    if(paymentTokenHeader.count > 0) {
                        if let paymentToken = paymentTokenHeader["Set-Cookie"] as? String {
                            let paymentToken = paymentToken.components(separatedBy: "payment-token=")[1]
                            completion(paymentToken)
                            return
                        }
                    }
                    completion(nil)
                }
            })
    }
    
    // Use this to fetch order details
    public func getOrder(with orderId: String, under outlet: String, using paymentToken: String) {
        // _links.self.href
        // "https://api-gateway-dev.ngenius-payments.com/transactions/outlets/0411acca-92f2-4305-a732-ac0f105d2a40/orders/403eeb5f-9987-4a91-9a18-03ee189f0a08"
    }
    
    // Use this to make payment against an order
    public func makePayment(for order: Order,
                            with paymentInfo: Payment,
                            using paymentToken: String,
                            on completion: @escaping (HttpResponseCallback)) {
        
        let paymentRequestHeaders = ["Authorization":"Bearer \(paymentToken)", "Content-Type":"application/vnd.ni-payment.v2+json"]
        let paymentData = try! JSONEncoder().encode(paymentInfo)
        let paymentDataJsonString = String(data: paymentData, encoding: .utf8)!
        
        if let paymentLink = order.orderLinks?.paymentLink {
            HTTPClient(url: paymentLink)?
                .withMethod(method: "PUT")
                .withHeaders(headers: paymentRequestHeaders)
                .withBodyData(data: paymentDataJsonString)
                .makeRequest(with: completion)
        }
    }
}
