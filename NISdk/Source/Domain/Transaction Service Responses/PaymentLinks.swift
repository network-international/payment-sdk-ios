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
    public let applePayLink: String?
}

extension PaymentLinks: Codable {
    
    private enum PaymentLinksCodingKeys: String, CodingKey {
        case paymentLink = "self"
        case cardPaymentLink = "payment:card"
        case savedCardPaymentLink = "payment:saved-card"
        case threeDSTermURL = "cnp:3ds"
        case applePayLink = "payment:apple_pay"
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
            let applePayLinkContainer = try paymentLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .applePayLink)
            applePayLink = try applePayLinkContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.applePayLink = nil
        }
    }
}
