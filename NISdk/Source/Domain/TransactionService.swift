//
//  NITransaction.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import PassKit

/* protocol conforming to transaction service */
@objc protocol TransactionService {
    @objc func authorizePayment(for authCode: String,
                                using authorizationLink: String,
                                on completion: @escaping ([String: String]) -> Void)
    
    @objc func getOrder(for orderLink: String,
                        using accessToken: String,
                        with completion: @escaping (HttpResponseCallback))
    
    @objc func makePayment(for order: OrderResponse,
                           with paymentInfo: PaymentRequest,
                           using paymentToken: String,
                           on completion: @escaping (HttpResponseCallback))
    
    @objc func postApplePayResponse(for order: OrderResponse,
                                    with applePayPaymentResponse: PKPayment,
                                    using paymentToken: String,
                                    on completion: @escaping (HttpResponseCallback))
}
