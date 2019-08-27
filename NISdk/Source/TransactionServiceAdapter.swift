//
//  NITransactionAdapter.swift
//  NISdk
//
//  Created by Johnny Peter on 09/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

@objc final class TransactionServiceAdapter: NSObject, TransactionService {
    
    // Use this to fetch token
    func authorizePayment(for authCode: String,
                                 using authorizationLink: String,
                                 on completion: @escaping (String?) -> Void) {
        
        let authorizationRequestHeaders = ["Accept": "application/vnd.ni-payment.v2+json",
                                           "Media-Type": "application/x-www-form-urlencoded",
                                           "Content-Type": "application/x-www-form-urlencoded"]
        HTTPClient(url: authorizationLink)?
            .withMethod(method: "POST")
            .withHeaders(headers: authorizationRequestHeaders)
            .withBodyData(data: "code=\(authCode)")
            .makeRequest(with: { (Data, URLResponse, Error) in
                if let headers = URLResponse?.getResponseHeaders() {
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
    
    // Use this to fetch order details TODO
    public func getOrder(with orderId: String, under outlet: String, using paymentToken: String) {
        // _links.self.href
        // "https://api-gateway-dev.ngenius-payments.com/transactions/outlets/0411acca-92f2-4305-a732-ac0f105d2a40/orders/403eeb5f-9987-4a91-9a18-03ee189f0a08"
    }
    
    // Use this to make payment against an order
    public func makePayment(for order: OrderResponse,
                            with paymentInfo: PaymentRequest,
                            using paymentToken: String,
                            on completion: @escaping (HttpResponseCallback)) {
        
        let paymentRequestHeaders = ["Authorization": "Bearer \(paymentToken)",
                                     "Content-Type": "application/vnd.ni-payment.v2+json"]
        
        let paymentData = try! JSONEncoder().encode(paymentInfo)
        
        if let paymentLink = order.embeddedData?.payment?[0].paymentLinks?.cardPaymentLink {
            HTTPClient(url: paymentLink)?
                .withMethod(method: "PUT")
                .withHeaders(headers: paymentRequestHeaders)
                .withBodyData(data: paymentData)
                .makeRequest(with: completion)
        }
    }
    
    public func postApplePayResponse(for order: OrderResponse,
                                     with applePayPaymentResponse: PKPayment,
                                     using paymentToken: String,
                                     on completion: @escaping OnPostApplePayResponseCallback) {
        
        let paymentRequestHeaders = ["Authorization": "Bearer \(paymentToken)",
            "Content-Type": "application/vnd.ni-payment.v2+json"]
        
        if let applePayLink = order.embeddedData?.payment?[0].paymentLinks?.applePayLink {
            HTTPClient(url: applePayLink)?
                .withMethod(method: "PUT")
                .withHeaders(headers: paymentRequestHeaders)
                .withBodyData(data: applePayPaymentResponse.token.paymentData)
                .makeRequest(with: { _, response, _ in
                    if let response = response {
                        if(response.isSuccess()) {
                            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                            return
                        }
                    }
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                })
        } else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
        }
    }
}
