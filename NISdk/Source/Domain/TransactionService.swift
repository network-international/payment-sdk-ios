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
                                    payerIp: String?,
                                    on completion: @escaping (HttpResponseCallback))
   
    @objc func postThreeDSAuthentications(for paymentResponse: PaymentResponse,
                                    with threeDSAuthenticationsRequest: ThreeDSAuthenticationsRequest,
                                    using paymentToken: String,
                                    on completion: @escaping (HttpResponseCallback))
    
    @objc func postThreeDSTwoChallengeResponse(for paymentResponse: PaymentResponse,
                                               using paymentToken: String,
                                               on completion: @escaping (HttpResponseCallback))
    
    @objc func getPayerIp(with url: String, using paymentToken: String, on completion: @escaping(HttpResponseCallback))
    
    @objc func getPayerIp(with url: String, on completion: @escaping(HttpResponseCallback))
    
    @objc func getVisaPlans(with url: String, using accessToken: String, cardToken: String?, cardNumber: String?, on completion: @escaping(HttpResponseCallback))
    
    @objc func partialAuth(with url: String, using accessToken: String, on completion: @escaping (HttpResponseCallback))
    
    @objc func aaniPayment(for url: String, with aaniRequest: AaniPayRequest, using accessToken: String, on completion: @escaping (HttpResponseCallback))
    
    @objc func aaniPaymentPooling(with url: String, using accessToken: String, on completion: @escaping (HttpResponseCallback))
}
