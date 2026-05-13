//
//  QPayInitArgs.swift
//  NISdk
//

import Foundation

class QPayInitArgs {
    /// Backend QPay endpoint that returns the QCB form fields.
    let qpayLink: String
    /// PayPageV2 origin (scheme + host) — used as baseURL for loadHTMLString so the form POST
    /// to QCB carries `Origin: https://paypage-sandbox.platform.network.ae` (whitelisted).
    let payPageOrigin: String
    /// Order self-link, used to refetch order state after the QCB callback.
    let orderLink: String
    let authUrl: String
    let authCode: String
    let currencyCode: String

    init(qpayLink: String, payPageOrigin: String, orderLink: String, authUrl: String, authCode: String, currencyCode: String) {
        self.qpayLink = qpayLink
        self.payPageOrigin = payPageOrigin
        self.orderLink = orderLink
        self.authUrl = authUrl
        self.authCode = authCode
        self.currencyCode = currencyCode
    }
}

extension OrderResponse {
    func toQPayInitArgs() throws -> QPayInitArgs {
        guard let qpayLink = embeddedData?.payment?.first?.paymentLinks?.qpayLink else {
            throw NSError(domain: "argument qpayLink missing", code: 99)
        }
        guard let payPageUrl = orderLinks?.payPageLink,
              let parsed = URL(string: payPageUrl),
              let scheme = parsed.scheme,
              let host = parsed.host else {
            throw NSError(domain: "argument payPageUrl missing", code: 99)
        }
        let payPageOrigin = "\(scheme)://\(host)/"
        guard let authUrl = orderLinks?.paymentAuthorizationLink else {
            throw NSError(domain: "argument authUrl missing", code: 99)
        }
        guard let orderLink = orderLinks?.orderLink else {
            throw NSError(domain: "argument orderLink missing", code: 99)
        }
        guard let authCode = getAuthCode() else {
            throw NSError(domain: "argument auth code missing", code: 99)
        }
        guard let currencyCode = self.amount?.currencyCode else {
            throw NSError(domain: "argument currencyCode missing", code: 99)
        }

        return QPayInitArgs(
            qpayLink: qpayLink,
            payPageOrigin: payPageOrigin,
            orderLink: orderLink,
            authUrl: authUrl,
            authCode: authCode,
            currencyCode: currencyCode
        )
    }
}
