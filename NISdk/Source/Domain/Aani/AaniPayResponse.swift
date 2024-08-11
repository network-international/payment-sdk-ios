//
//  AaniPayResponse.swift
//  NISdk
//
//  Created by Gautam Chibde on 07/08/24.
//

import Foundation

class AaniPayResponse: NSObject, Codable {
    let id: String
    let links: AaniLinks
    let aani: Aani
    let amount: Amount
    let state: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case links = "_links"
        case aani
        case amount
        case state
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.links = try container.decode(AaniLinks.self, forKey: .links)
        self.aani = try container.decode(Aani.self, forKey: .aani)
        self.amount = try container.decode(Amount.self, forKey: .amount)
        self.state = try container.decode(String.self, forKey: .state)
    }
}

class AaniLinks: NSObject, Codable {
    let aaniStatus: String?
    let selfLink: String?
    
    enum CodingKeys: String, CodingKey {
        case aaniStatus = "cnp:aani-status"
        case selfLink = "self"
    }
    
    private enum hrefCodingKeys: String, CodingKey {
        case href
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            let aaniStatusContainer = try container.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .aaniStatus)
            self.aaniStatus = try aaniStatusContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.aaniStatus = nil
        }
        
        do {
            let selfLinkContainer = try container.nestedContainer(keyedBy: hrefCodingKeys.self, forKey: .aaniStatus)
            self.selfLink = try selfLinkContainer.decodeIfPresent(String.self, forKey: .href)
        } catch {
            self.selfLink = nil
        }
    }
}

class Aani: NSObject, Codable {
    let deepLinkUrl: String
    
    public required init(deepLinkUrl: String) {
        self.deepLinkUrl = deepLinkUrl
    }
}
