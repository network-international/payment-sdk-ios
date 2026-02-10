//
//  ClickToPayArgs.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import Foundation

class ClickToPayArgs {
    let amount: Double
    let currencyCode: String
    let authUrl: String
    let authCode: String
    let payPageUrl: String
    let outletId: String
    let orderId: String
    let paymentRef: String
    let unifiedClickToPayUrl: String
    let orderUrl: String
    let accessToken: String
    let paymentCookie: String

    init(amount: Double,
         currencyCode: String,
         authUrl: String,
         authCode: String,
         payPageUrl: String,
         outletId: String,
         orderId: String,
         paymentRef: String,
         unifiedClickToPayUrl: String,
         orderUrl: String,
         accessToken: String,
         paymentCookie: String) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.authUrl = authUrl
        self.authCode = authCode
        self.payPageUrl = payPageUrl
        self.outletId = outletId
        self.orderId = orderId
        self.paymentRef = paymentRef
        self.unifiedClickToPayUrl = unifiedClickToPayUrl
        self.orderUrl = orderUrl
        self.accessToken = accessToken
        self.paymentCookie = paymentCookie
    }
}

extension OrderResponse {
    func toClickToPayArgs() throws -> ClickToPayArgs {
        guard let payment = embeddedData?.payment?.first else {
            throw NSError(domain: "argument payments missing", code: 99)
        }

        guard let amount = self.amount?.value else {
            throw NSError(domain: "argument amount missing", code: 99)
        }

        guard let currencyCode = self.amount?.currencyCode else {
            throw NSError(domain: "argument currencyCode missing", code: 99)
        }

        guard let authUrl = orderLinks?.paymentAuthorizationLink else {
            throw NSError(domain: "argument authUrl missing", code: 99)
        }

        guard let payPageUrl = orderLinks?.payPageLink else {
            throw NSError(domain: "argument payPageUrl missing", code: 99)
        }

        guard let authCode = getAuthCode() else {
            throw NSError(domain: "argument auth code missing", code: 99)
        }

        guard let outletId = self.outletId ?? payment.outletId else {
            throw NSError(domain: "argument outletId missing", code: 99)
        }

        guard let orderId = self.reference else {
            throw NSError(domain: "argument orderId missing", code: 99)
        }

        let paymentRef = payment.reference

        // Build the unified-click-to-pay URL from the pay page host.
        // This endpoint is served by the pay page proxy at /api/outlets/...
        guard let payPageHost = URL(string: payPageUrl)?.host else {
            throw NSError(domain: "argument payPageUrl host missing", code: 99)
        }

        let unifiedClickToPayUrl = "https://\(payPageHost)/api/outlets/\(outletId)/orders/\(orderId)/payments/\(paymentRef)/unified-click-to-pay"

        // Use the order self link for checking status after 3DS, or build from pay page host
        let orderUrl = orderLinks?.orderLink ?? "https://\(payPageHost)/api/outlets/\(outletId)/orders/\(orderId)"

        return ClickToPayArgs(
            amount: amount,
            currencyCode: currencyCode,
            authUrl: authUrl,
            authCode: authCode,
            payPageUrl: payPageUrl,
            outletId: outletId,
            orderId: orderId,
            paymentRef: paymentRef,
            unifiedClickToPayUrl: unifiedClickToPayUrl,
            orderUrl: orderUrl,
            accessToken: "", // Will be obtained during authorization
            paymentCookie: "" // Will be obtained during authorization
        )
    }
}
