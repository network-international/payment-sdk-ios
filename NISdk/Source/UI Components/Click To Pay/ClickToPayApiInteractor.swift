//
//  ClickToPayApiInteractor.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation

class ClickToPayApiInteractor {

    /// Submit the Click to Pay checkout response to the unified-click-to-pay API
    func submitPayment(unifiedClickToPayUrl: String,
                       checkoutResponse: String,
                       srcDigitalCardId: String?,
                       accessToken: String,
                       paymentCookie: String,
                       completion: @escaping (ClickToPayPaymentResult) -> Void) {

        var bodyDict: [String: Any] = [
            "checkoutResponse": checkoutResponse
        ]
        if let cardId = srcDigitalCardId {
            bodyDict["srcDigitalCardId"] = cardId
        }

        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict) else {
            completion(.failed("Failed to serialize request body"))
            return
        }

        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer \(accessToken)",
            "Access-Token": accessToken,
            "Cookie": paymentCookie
        ]
        // Extract payment-token value from cookie string "payment-token=XXX"
        let cookieParts = paymentCookie.components(separatedBy: "=")
        if cookieParts.count >= 2 {
            headers["Payment-Token"] = cookieParts.dropFirst().joined(separator: "=")
        }

        HTTPClient(url: unifiedClickToPayUrl)?
            .withMethod(method: "POST")
            .withHeaders(headers: headers)
            .withBodyData(data: bodyData)
            .makeRequest(with: { [weak self] data, response, error in
                if let error = error {
                    completion(.failed(error.localizedDescription))
                    return
                }

                guard let data = data else {
                    completion(.failed("No response data"))
                    return
                }

                self?.parsePaymentResponse(data: data, completion: completion)
            })
    }

    /// Build the unified-click-to-pay URL from order details
    static func buildUnifiedClickToPayUrl(basePaymentUrl: String,
                                          outletId: String,
                                          orderId: String,
                                          paymentRef: String) -> String {
        let baseUrl: String
        if let range = basePaymentUrl.range(of: "/api/") {
            baseUrl = String(basePaymentUrl[..<range.lowerBound])
        } else if let range = basePaymentUrl.range(of: "/transactions/") {
            baseUrl = String(basePaymentUrl[..<range.lowerBound])
        } else {
            baseUrl = basePaymentUrl
        }
        return "\(baseUrl)/api/outlets/\(outletId)/orders/\(orderId)/payments/\(paymentRef)/unified-click-to-pay"
    }

    private func parsePaymentResponse(data: Data, completion: @escaping (ClickToPayPaymentResult) -> Void) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failed("Invalid response format"))
                return
            }

            let state = json["state"] as? String ?? ""

            switch state {
            case "AUTHORISED":
                completion(.authorised)
            case "PURCHASED":
                completion(.purchased)
            case "CAPTURED":
                completion(.captured)
            case "POST_AUTH_REVIEW":
                completion(.postAuthReview)
            case "AWAIT_3DS":
                // The unified-click-to-pay response wraps payment data inside
                // order._embedded.payment[0] with internal service URLs.
                // Trigger polling to fetch the order from the gateway which returns
                // properly structured PaymentResponse with public URLs and 3DS config.
                completion(.pending)
            case "PENDING":
                completion(.pending)
            case "FAILED":
                let message = json["message"] as? String ?? "Payment failed"
                completion(.failed(message))
            default:
                completion(.failed("Unknown payment state: \(state)"))
            }
        } catch {
            completion(.failed("Failed to parse response: \(error.localizedDescription)"))
        }
    }
}
