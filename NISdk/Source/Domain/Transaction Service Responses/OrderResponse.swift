//
//  Order.swift
//  NISdk
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

class BenefitInitArgs {
    /// Gateway endpoint that starts a Benefit payment and returns the hosted redirect URL.
    let benefitLink: String
    /// Order self-link, polled for the final payment state once the payer returns from Benefit.
    let orderLink: String

    init(benefitLink: String, orderLink: String) {
        self.benefitLink = benefitLink
        self.orderLink = orderLink
    }

    static let supportedCurrency = "BHD"
}


@objc public class OrderResponse: NSObject, Codable {
    public var _id: String?
    public var type: String?
    public var action: String?
    public var amount: Amount?
    public var formattedAmount: String?
    public var language: String?
    public var merchantAttributes: [String:String]?
    public var emailAddress: String?
    public var reference: String?
    public var outletId: String?
    public var createDateTime: String?
    public var referrer: String?
    public var orderSummary: OrderSummary?
    public var formattedOrderSummary: FormattedOrderSummary?
    public var billingAddress: BillingAddress?
    public var paymentMethods: PaymentMethods?
    public var orderLinks: OrderLinks?
    public var embeddedData: EmbeddedData?
    public var savedCard: SavedCard?
    public var visSavedCardMatchedCandidates: VisSavedCardMatchedCandidates?
    public var isSaudiPaymentEnabled: Bool?
    public var merchantDetails: MerchantDetails?

    public enum OrderCodingKeys: String, CodingKey {
        case _id
        case type
        case action
        case amount
        case formattedAmount
        case language
        case merchantAttributes
        case emailAddress
        case reference
        case savedCard
        case outletId
        case createDateTime
        case referrer
        case orderSummary
        case formattedOrderSummary
        case billingAddress
        case paymentMethods
        case orderLinks = "_links"
        case embeddedData = "_embedded"
        case visSavedCardMatchedCandidates = "visSavedCardMatchedCandidates"
        case isSaudiPaymentEnabled
        case merchantDetails
    }
    
    public func getAuthCode() -> String? {
        if let payPageLink = orderLinks?.payPageLink,
            let url = URLComponents(string: payPageLink) {
            return url.queryItems?.first(where: { $0.name == "code" })?.value
        }
        return nil
    }
    
    @objc public static func decodeFrom(data: Data) throws -> OrderResponse {
        do {
            let orderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
            return orderResponse
        } catch let error {
            throw error
        }
    }
    
    override required init() {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let OrderResponseContainer = try decoder.container(keyedBy: OrderCodingKeys.self)

        _id = try OrderResponseContainer.decodeIfPresent(String.self, forKey: ._id) ?? ""
        type = try OrderResponseContainer.decode(String.self, forKey: .type)
        action = try OrderResponseContainer.decode(String.self, forKey: .action)
        isSaudiPaymentEnabled = try OrderResponseContainer.decodeIfPresent(Bool.self, forKey: .isSaudiPaymentEnabled)
        amount = try OrderResponseContainer.decodeIfPresent(Amount.self, forKey: .amount)
        formattedAmount = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .formattedAmount)
        language = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .language)
        merchantAttributes = try OrderResponseContainer.decodeIfPresent([String:String].self, forKey: .merchantAttributes)
        emailAddress = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .emailAddress)
        reference = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .reference)
        outletId = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .outletId)
        createDateTime = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .createDateTime)
        referrer = try OrderResponseContainer.decodeIfPresent(String.self, forKey: .referrer)
        orderSummary = try OrderResponseContainer.decodeIfPresent(OrderSummary.self, forKey: .orderSummary)
        formattedOrderSummary = try OrderResponseContainer.decodeIfPresent(FormattedOrderSummary.self, forKey: .formattedOrderSummary)
        billingAddress = try OrderResponseContainer.decodeIfPresent(BillingAddress.self, forKey: .billingAddress)
        paymentMethods = try OrderResponseContainer.decodeIfPresent(PaymentMethods.self, forKey: .paymentMethods)
        orderLinks = try OrderResponseContainer.decodeIfPresent(OrderLinks.self, forKey:.orderLinks)
        embeddedData = try OrderResponseContainer.decodeIfPresent(EmbeddedData.self, forKey: .embeddedData)
        savedCard = try OrderResponseContainer.decodeIfPresent(SavedCard.self, forKey: .savedCard)
        visSavedCardMatchedCandidates = try OrderResponseContainer.decodeIfPresent(VisSavedCardMatchedCandidates.self, forKey: .visSavedCardMatchedCandidates)
        merchantDetails = try OrderResponseContainer.decodeIfPresent(MerchantDetails.self, forKey: .merchantDetails)
    }
    
    class Builder {
        private var orderResponse = OrderResponse()
        
        func withId(_id: String) -> Builder {
            orderResponse._id = _id
            return self
        }
        
        func withAction(action: String) -> Builder {
            orderResponse.action = action
            return self
        }
        
        func build() -> OrderResponse {
            return orderResponse
        }
        
    }
}

extension OrderResponse {
    internal func toPartialAuthArgs(accessToken: String?) throws -> PartialAuthArgs {
        guard let payment = embeddedData?.payment?.first else {
            throw NSError(domain: "argument payments missing", code: 99)
        }
        guard let partialAmount = payment.authResponse?.partialAmount else {
            throw NSError(domain: "argument partialAmount missing", code: 99)
        }
        
        guard let amount = payment.authResponse?.amount else {
            throw NSError(domain: "argument amount missing", code: 99)
        }
        
        guard let currency = self.amount?.currencyCode else {
            throw NSError(domain: "argument currency missing", code: 99)
        }
        
        guard let acceptUrl = payment.paymentLinks?.partialAuthAccept else {
            throw NSError(domain: "argument partial Auth acceptUrl missing", code: 99)
        }
        
        guard let declineUrl = payment.paymentLinks?.partialAuthDecline else {
            throw NSError(domain: "argument partial Auth declineUrl missing", code: 99)
        }
        
        guard let token = accessToken else {
            throw NSError(domain: "payment token missing", code: 99)
        }
        
        return PartialAuthArgs(
            partialAmount: partialAmount,
            amount: amount,
            currency: currency,
            acceptUrl: acceptUrl,
            declineUrl: declineUrl,
            issuingOrg: payment.paymentMethod?.issuingOrg,
            accessToken: token
        )
    }

    /// Benefit is only offered for a BHD purchase on an outlet that lists BENEFIT among its card
    /// schemes. The gateway rejects anything else, so the button must stay hidden in those cases.
    var isBenefitSupported: Bool {
        guard paymentMethods?.card?.contains(.benefit) == true else { return false }
        guard action?.uppercased() == "PURCHASE" else { return false }
        return amount?.currencyCode?.uppercased() == BenefitInitArgs.supportedCurrency
    }

    func toBenefitInitArgs() throws -> BenefitInitArgs {
        guard let benefitLink = benefitPaymentLink else {
            throw NSError(domain: "argument benefitLink missing", code: 99)
        }
        guard let orderLink = orderLinks?.orderLink else {
            throw NSError(domain: "argument orderLink missing", code: 99)
        }
        return BenefitInitArgs(benefitLink: benefitLink, orderLink: orderLink)
    }

    /// The order carries no `payment:benefit` rel, so the endpoint is derived from the payment's own
    /// `self` href. Deriving it keeps the gateway host authoritative instead of hard-coding one.
    private var benefitPaymentLink: String? {
        guard let paymentSelfLink = embeddedData?.payment?.first?.paymentLinks?.paymentLink,
              !paymentSelfLink.isEmpty else {
            return nil
        }
        let base = paymentSelfLink.hasSuffix("/") ? String(paymentSelfLink.dropLast()) : paymentSelfLink
        return "\(base)/benefit"
    }

    /// The buy-now-pay-later providers this order can be paid with, in the order they are offered.
    /// A provider qualifies purely on the outlet listing it among the order's APMs: which markets
    /// it lends in, whether it will lend to this shopper, and whether the basket suits it are all
    /// the provider's decisions, taken when the checkout is created.
    ///
    /// A basket under the provider's published minimum does *not* remove the row — the hosted
    /// paypage keeps it visible and says why on selection, and an option that silently vanishes
    /// reads as the SDK being broken rather than as the basket being too small.
    var supportedBnplProviders: [BnplProvider] {
        guard let apms = paymentMethods?.apm else { return [] }
        return BnplProvider.allCases.filter { provider in
            guard apms.contains(where: { $0.caseInsensitiveCompare(provider.apmName) == .orderedSame }) else {
                return false
            }
            return bnplLink(for: provider) != nil
        }
    }

    /// True when the basket is below the smallest the provider will finance. The row stays on the
    /// page either way; this is what puts the reason under it instead of letting the payer tap
    /// through to a checkout the provider is certain to refuse. Currencies the provider publishes
    /// no minimum for are left to the gateway.
    func isBelowBnplMinimum(for provider: BnplProvider) -> Bool {
        guard let amount = self.amount,
              let currency = amount.currencyCode?.uppercased(),
              let minimum = provider.minimumAmounts[currency] else {
            return false
        }
        return amount.majorUnitValue() < minimum
    }

    /// The provider's minimum for this order's currency, formatted for display, or nil when it
    /// publishes none.
    func formattedBnplMinimum(for provider: BnplProvider) -> String? {
        guard let currency = amount?.currencyCode?.uppercased(),
              let minimum = provider.minimumAmounts[currency] else {
            return nil
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US")
        let value = formatter.string(from: NSNumber(value: minimum)) ?? String(format: "%.0f", minimum)
        return "\(currency) \(value)"
    }

    func toBnplInitArgs(for provider: BnplProvider) throws -> BnplInitArgs {
        guard let checkoutLink = bnplLink(for: provider) else {
            throw NSError(domain: "argument \(provider.rawValue)Link missing", code: 99)
        }
        guard let orderLink = orderLinks?.orderLink else {
            throw NSError(domain: "argument orderLink missing", code: 99)
        }
        // The return URLs must be ones the provider will accept and redirect a browser to. The
        // hosted paypage is the only such address the order carries, so the SDK reuses it exactly as
        // the web checkout does — the WebView intercepts these before they ever load, so the page
        // they point at is never fetched.
        guard let payPageLink = orderLinks?.payPageLink,
              let parsed = URL(string: payPageLink),
              let scheme = parsed.scheme,
              let host = parsed.host,
              let authCode = getAuthCode() else {
            throw NSError(domain: "argument payPageUrl missing", code: 99)
        }
        let returnBase = "\(scheme)://\(host)/v2?code=\(authCode)"
        let resultParam = BnplInitArgs.resultParam
        let method = provider.rawValue

        return BnplInitArgs(
            provider: provider,
            checkoutLink: checkoutLink,
            acceptLink: "\(checkoutLink)/accept",
            orderLink: orderLink,
            successUrl: "\(returnBase)&payment_method=\(method)&\(resultParam)=success",
            cancelUrl: "\(returnBase)&\(resultParam)=cancel",
            failureUrl: "\(returnBase)&payment_method=\(method)&\(resultParam)=failure"
        )
    }

    /// `payment:tamara` / `payment:tabby` when the gateway advertises it, otherwise derived from the
    /// payment's own `self` href the way the Benefit endpoint is — an outlet that lists the APM
    /// without the rel would otherwise lose the option.
    private func bnplLink(for provider: BnplProvider) -> String? {
        if let link = embeddedData?.getBnplLink(for: provider), !link.isEmpty {
            return link
        }
        guard let paymentSelfLink = embeddedData?.payment?.first?.paymentLinks?.paymentLink,
              !paymentSelfLink.isEmpty else {
            return nil
        }
        let base = paymentSelfLink.hasSuffix("/") ? String(paymentSelfLink.dropLast()) : paymentSelfLink
        return "\(base)/\(provider.pathSegment)"
    }
}
