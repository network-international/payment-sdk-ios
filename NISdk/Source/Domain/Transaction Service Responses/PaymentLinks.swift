//
//  PaymentLinks.swift
//  NISdk
//
//  Created by Johnny Peter on 21/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct PaymentLinks {
    public let paymentLink: String?
    public let cardPaymentLink: String?
    public let savedCardPaymentLink: String?
    public let threeDSTermURL: String?
    public let threeDSTwoAuthenticationURL: String?
    public let threeDSTwoChallengeResponseURL: String?
    public let applePayLink: String?
    public let partialAuthAccept: String?
    public let partialAuthDecline: String?
    public let aaniPaymentLink: String?
}

extension PaymentLinks: Codable {
    
    private enum PaymentLinksCodingKeys: String, CodingKey {
        case paymentLink = "self"
        case cardPaymentLink = "payment:card"
        case savedCardPaymentLink = "payment:saved-card"
        case threeDSTermURL = "cnp:3ds"
        case threeDSTwoAuthenticationURL = "cnp:3ds2-authentication"
        case threeDSTwoChallengeResponseURL = "cnp:3ds2-challenge-response"
        case applePayLink = "payment:apple_pay"
        case partialAuthAccept = "payment:partial-auth-accept"
        case partialAuthDecline = "payment:partial-auth-decline"
        case aaniPaymentLink = "payment:aani"
    }
    
    private enum hrefCodingKeys: String, CodingKey {
        case href
    }
    
    public init(from decoder: Decoder) throws {
        let paymentLinksContainer = try decoder.container(keyedBy: PaymentLinksCodingKeys.self)
        
        do {
            let paymentLinkContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .paymentLink)
            paymentLink = try paymentLinkContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.paymentLink = nil
        }
        
        do {
            let cardPaymentLinkContainer: KeyedDecodingContainer? = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .cardPaymentLink)
            cardPaymentLink = try cardPaymentLinkContainer?.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.cardPaymentLink = nil
        }
        
        do {
            let savedCardPaymentContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .savedCardPaymentLink)
            savedCardPaymentLink = try savedCardPaymentContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.savedCardPaymentLink = nil
        }
        
        do {
            let threeDSTermURLContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .threeDSTermURL)
            threeDSTermURL = try threeDSTermURLContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.threeDSTermURL = nil
        }
        
        do {
            let threeDSTwoAuthURLContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .threeDSTwoAuthenticationURL)
            threeDSTwoAuthenticationURL = try threeDSTwoAuthURLContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.threeDSTwoAuthenticationURL = nil
        }

        do {
            let threeDSTwoAuthURLContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .threeDSTwoChallengeResponseURL)
            threeDSTwoChallengeResponseURL = try threeDSTwoAuthURLContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.threeDSTwoChallengeResponseURL = nil
        }
        
        do {
            let applePayLinkContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .applePayLink)
            applePayLink = try applePayLinkContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.applePayLink = nil
        }
        
        do {
            let partialAuthAcceptContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .partialAuthAccept)
            partialAuthAccept = try partialAuthAcceptContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.partialAuthAccept = nil
        }
        
        do {
            let partialAuthDeclineContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .partialAuthDecline)
            partialAuthDecline = try partialAuthDeclineContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.partialAuthDecline = nil
        }
        
        do {
            let aaniPaymentLinkContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .aaniPaymentLink)
            aaniPaymentLink = try aaniPaymentLinkContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.aaniPaymentLink = nil
        }
    }
}
