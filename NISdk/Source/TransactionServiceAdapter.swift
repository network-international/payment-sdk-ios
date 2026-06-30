//
//  NITransactionAdapter.swift
//  NISdk
//
//  Created by Johnny Peter on 09/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import os.log
import PassKit

@objc final class TransactionServiceAdapter: NSObject, TransactionService {

    // Use this to fetch token
    func authorizePayment(for authCode: String,
                                 using authorizationLink: String,
                                 on completion: @escaping ([String:String]) -> Void) {
        os_log("[NISdk] authorizePayment — link: %{public}@", log: NISdkLogger.auth, type: .debug, authorizationLink)
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
                        if let headerKey = $0.key as? String {
                            return headerKey.contains("Set-Cookie")
                        }
                        return false
                    }
                    if(paymentTokenHeader.count > 0) {
                        if let setCookieValue = paymentTokenHeader["Set-Cookie"] as? String {
                            let tokens = TokenUtils.extractTokens(headerValue: setCookieValue, tokenPatterns: ["payment-token", "access-token"])
                            os_log("[NISdk] authorizePayment — tokens received: payment-token=%{public}@, access-token=%{public}@",
                                   log: NISdkLogger.auth, type: .debug,
                                   tokens["payment-token"] != nil ? "present" : "missing",
                                   tokens["access-token"] != nil ? "present" : "missing")
                            completion(tokens)
                            return
                        }
                    }
                    os_log("[NISdk] authorizePayment — no payment token in response headers", log: NISdkLogger.auth, type: .error)
                    completion([:])
                }
            })
    }

    // Use this to fetch order details
    public func getOrder(for orderLink: String,
                         using accessToken: String,
                         with completion: @escaping (HttpResponseCallback)) {
        os_log("[NISdk] getOrder — link: %{public}@", log: NISdkLogger.payment, type: .debug, orderLink)
        let orderRequestHeaders = ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/vnd.ni-payment.v2+json"]

        HTTPClient(url: orderLink)?
            .withMethod(method: "GET")
            .withHeaders(headers: orderRequestHeaders)
            .makeRequest(with: completion)
    }

    // Use this to make payment against an order
    public func makePayment(for order: OrderResponse,
                            with paymentInfo: PaymentRequest,
                            using paymentToken: String,
                            on completion: @escaping (HttpResponseCallback)) {
        os_log("[NISdk] makePayment — orderRef: %{public}@", log: NISdkLogger.payment, type: .debug, order.reference ?? "unknown")
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

    // Use this to post apple pay response to transaction service
    public func postApplePayResponse(for order: OrderResponse,
                                     with applePayPaymentResponse: PKPayment,
                                     using accessToken: String,
                                     payerIp: String?,
                                     on completion: @escaping (HttpResponseCallback)) {
        os_log("[NISdk] postApplePayResponse — orderRef: %{public}@, payerIp: %{public}@",
               log: NISdkLogger.payment, type: .debug, order.reference ?? "unknown", payerIp ?? "nil")
        let paymentRequestHeaders = ["Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/vnd.ni-payment.v2+json"]
        var queryParams: [String: String] = [:]
        if let payerIp = payerIp {
            queryParams = ["payer_ip": payerIp]
        }

        if let applePayLink = order.embeddedData?.payment?[0].paymentLinks?.applePayLink {
            HTTPClient(url: applePayLink)?
                .withMethod(method: "PUT")
                .withHeaders(headers: paymentRequestHeaders)
                .withQueryParams(queries: queryParams)
                .withBodyData(data: applePayPaymentResponse.token.paymentData)
                .makeRequest(with: completion)
        } else {
            completion(nil, nil, nil)
        }
    }

    func postThreeDSAuthentications(for paymentResponse: PaymentResponse,
                                    with threeDSAuthenticationsRequest: ThreeDSAuthenticationsRequest,
                                    using paymentToken: String,
                                    on completion: @escaping (HttpResponseCallback)) {

        let authRequestHeaders = ["Authorization": "Bearer \(paymentToken)",
            "Content-Type": "application/vnd.ni-payment.v2+json"]

        let threeDSAuthData = try! JSONEncoder().encode(threeDSAuthenticationsRequest)

        if let authenticationsLink = paymentResponse.paymentLinks?.threeDSTwoAuthenticationURL {
            os_log("[NISdk] postThreeDSAuthentications — link: %{public}@", log: NISdkLogger.payment, type: .debug, authenticationsLink)
            HTTPClient(url: authenticationsLink)?
                .withMethod(method: "POST")
                .withHeaders(headers: authRequestHeaders)
                .withBodyData(data: threeDSAuthData)
                .makeRequest(with: completion)
        } else {
            os_log("[NISdk] postThreeDSAuthentications — no 3DS authentication link found", log: NISdkLogger.payment, type: .error)
            completion(nil, nil, nil)
        }
    }

    func postThreeDSTwoChallengeResponse(for paymentResponse: PaymentResponse,
                                         using paymentToken: String,
                                         on completion: @escaping (HttpResponseCallback)) {
        let authRequestHeaders = ["Authorization": "Bearer \(paymentToken)",
            "Content-Type": "application/vnd.ni-payment.v2+json"]

        if let authenticationsLink = paymentResponse.paymentLinks?.threeDSTwoChallengeResponseURL {
            os_log("[NISdk] postThreeDSTwoChallengeResponse — link: %{public}@", log: NISdkLogger.payment, type: .debug, authenticationsLink)
            HTTPClient(url: authenticationsLink)?
                .withMethod(method: "POST")
                .withHeaders(headers: authRequestHeaders)
                .makeRequest(with: completion)
        } else {
            os_log("[NISdk] postThreeDSTwoChallengeResponse — no 3DS challenge response link found", log: NISdkLogger.payment, type: .error)
            completion(nil, nil, nil)
        }
    }

    func getPayerIp(with url: String, using paymentToken: String, on completion: @escaping(HttpResponseCallback)) {
        let headers = ["Authorization": "Bearer \(paymentToken)",
            "Content-Type": "application/vnd.ni-payment.v2+json"]

        HTTPClient(url: url)?
            .withMethod(method: "GET")
            .withHeaders(headers: headers)
            .makeRequest(with: completion)
    }

    func getPayerIp(with url: String, on completion: @escaping (HttpResponseCallback)) {
        HTTPClient(url: url)?
            .withMethod(method: "GET")
            .makeRequest(with: completion)
    }

    func doSavedCardPayment(for url: String, with savedCardInfo: SavedCardRequest, using accessToken:String, on completion: @escaping(HttpResponseCallback)) {
        os_log("[NISdk] doSavedCardPayment — url: %{public}@", log: NISdkLogger.payment, type: .debug, url)
        let authorizationRequestHeaders = ["Accept": "application/vnd.ni-payment.v2+json",
                                           "Media-Type": "application/x-www-form-urlencoded",
                                           "Content-Type": "application/vnd.ni-payment.v2+json",
                                           "Authorization": "payment \(accessToken)"]

        let data = try! JSONEncoder().encode(savedCardInfo)
        HTTPClient(url: url)?
            .withMethod(method: "PUT")
            .withHeaders(headers: authorizationRequestHeaders)
            .withBodyData(data: data)
            .makeRequest(with: completion)
    }

    func getVisaPlans(with url: String, using accessToken: String, cardToken: String?, cardNumber: String?, on completion: @escaping (HttpResponseCallback)) {
        let authorizationRequestHeaders = ["Accept": "application/vnd.ni-payment.v2+json",
                                           "Content-Type": "application/vnd.ni-payment.v2+json",
                                           "Authorization": "Bearer \(accessToken)"]
        let data = try! JSONEncoder().encode(VisaEligibilityRequets(cardToken: cardToken, pan: cardNumber))
        HTTPClient(url: "\(url)/vis/eligibility-check")?
            .withMethod(method: "POST")
            .withHeaders(headers: authorizationRequestHeaders)
            .withBodyData(data: data)
            .makeRequest(with: completion)
    }

    func partialAuth(with url: String,
                           using accessToken: String,
                           on completion: @escaping (HttpResponseCallback)) {
        let authorizationRequestHeaders = ["Accept": "application/vnd.ni-payment.v2+json",
                                           "Content-Type": "application/vnd.ni-payment.v2+json",
                                           "Authorization": "Bearer \(accessToken)"]
        HTTPClient(url: url)?
            .withMethod(method: "PUT")
            .withHeaders(headers: authorizationRequestHeaders)
            .makeRequest(with: completion)
    }

    func aaniPayment(for url: String, with aaniRequest: AaniPayRequest, using accessToken: String, on completion: @escaping (HttpResponseCallback)) {
        os_log("[NISdk] aaniPayment — url: %{public}@", log: NISdkLogger.aani, type: .debug, url)
        let authorizationRequestHeaders = ["Content-Type": "application/vnd.ni-payment.v2+json",
                                           "Authorization": "Bearer \(accessToken)"]
        let data = try! JSONEncoder().encode(aaniRequest)
        HTTPClient(url: url)?
            .withMethod(method: "POST")
            .withBodyData(data: data)
            .withHeaders(headers: authorizationRequestHeaders)
            .makeRequest(with: completion)
    }

    func aaniPaymentPooling(with url: String, using accessToken: String, on completion: @escaping (HttpResponseCallback)) {
        os_log("[NISdk] aaniPaymentPolling — url: %{public}@", log: NISdkLogger.aani, type: .debug, url)
        let authorizationRequestHeaders = ["Content-Type": "application/vnd.ni-payment.v2+json",
                                           "Authorization": "Bearer \(accessToken)"]
        HTTPClient(url: url)?
            .withMethod(method: "GET")
            .withHeaders(headers: authorizationRequestHeaders)
            .makeRequest(with: completion)
    }
}
