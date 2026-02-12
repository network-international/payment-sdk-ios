//
//  TermsConfig 2.swift
//  Pods
//
//  Created by Prasath R on 10/02/26.
//


import Foundation

struct TermsConfig {
    let termsText: String
    let linkText: String
}

enum OrderType: String {
    case recurring = "RECURRING"
    case installment = "INSTALLMENT"
    case unscheduled = "UNSCHEDULED"
    case unknown
}

final class TermsConfigResolver {

    static func resolve(
        orderType: OrderType,
        isSubscriptionOrder: Bool
    ) -> TermsConfig {

        switch (orderType, isSubscriptionOrder) {

        case (.recurring, true):
            return TermsConfig(
                termsText: "recurring_consent_terms".localized,
                linkText: "consent_link_text".localized
            )

        case (.installment, true):
            return TermsConfig(
                termsText: "installment_consent_terms".localized,
                linkText: "consent_link_text".localized
            )

        case (.unscheduled, _):
            return TermsConfig(
                termsText: "unscheduled_consent_terms".localized,
                linkText: "consent_link_text".localized
            )

        default:
            return TermsConfig(
                termsText: "default_terms".localized,
                linkText: "default_consent_link_text".localized
            )
        }
    }
}
