//
//  OrderLinks.swift
//  NISdk
//
//  Created by Johnny Peter on 19/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public struct OrderLinks {
    public let paymentLink: String?
    public let paymentAuthorizationLink: String?
    public let orderLink: String?
    public let payPageLink: String?
}

extension OrderLinks: Codable {
    
    private enum OrderLinksCodingKeys: String, CodingKey {
        case paymentLink = "cnp:payment-link"
        case paymentAuthorizationLink = "payment-authorization"
        case orderLink = "self"
        case payPageLink = "payment"
    }
    
    private enum hrefCodingKeys: String, CodingKey {
       case href
    }
    
    public init(from decoder: Decoder) throws {
        let orderLinksContainer = try decoder.container(keyedBy: OrderLinksCodingKeys.self)
        
        do {
            let paymentLinkContainer = try orderLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .paymentLink)
            paymentLink = try paymentLinkContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.paymentLink = nil
        }
        
        do {
            let paymentAuthorizationLinkContainer = try orderLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .paymentAuthorizationLink)
            paymentAuthorizationLink = try paymentAuthorizationLinkContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
           self.paymentAuthorizationLink = nil
        }
        
        
        do {
            let orderLinkContainer = try orderLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .orderLink)
            orderLink = try orderLinkContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.orderLink = nil
        }
        
        
        do {
            let payPageLinkContainer = try orderLinksContainer.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .payPageLink)
            payPageLink = try payPageLinkContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.payPageLink = nil
        }
    }
}
