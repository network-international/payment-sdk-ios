//
//  ThreeDSTwoConfig.swift
//  NISdk
//
//  Created by Johnny Peter on 30/03/22.
//  Copyright © 2022 Network International. All rights reserved.
//

import Foundation

public struct ThreeDSTwoConfig: Codable {
    var directoryServerID: String?
    var threeDSServerTransID: String?
    var messageVersion: String?
    var transStatus: String?
    var threeDSMethodURL: String?
    var acsTransID: String?
    var acsReferenceNumber: String?
    var acsSignedContent: String?
    var base64EncodedCReq: String?
    var acsURL: String?
    
    private enum ThreeDSTwoConfigCodingKeys: String, CodingKey {
        case directoryServerID
        case threeDSServerTransID
        case messageVersion
        case transStatus
        case threeDSMethodURL
        case acsTransID
        case acsReferenceNumber
        case acsSignedContent
        case base64EncodedCReq
        case acsURL
    }
    
    public init(from decoder: Decoder) throws {
        let threeDSTwoConfigContainer = try decoder.container(keyedBy: ThreeDSTwoConfigCodingKeys.self)
        
        do {
            self.directoryServerID = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .directoryServerID)
        } catch {
            self.directoryServerID = nil
        }
        
        do {
            self.threeDSServerTransID = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .threeDSServerTransID)
        } catch {
            self.threeDSServerTransID = nil
        }
        
        do {
            self.messageVersion = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .messageVersion)
        } catch {
            self.messageVersion = nil
        }
        
        do {
            self.transStatus = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .transStatus)
        } catch {
            self.transStatus = nil
        }
        
        do {
            self.threeDSMethodURL = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .threeDSMethodURL)
        } catch {
            self.threeDSMethodURL = nil
        }
        
        do {
            self.acsTransID = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .acsTransID)
        } catch {
            self.acsTransID = nil
        }
        
        do {
            self.acsReferenceNumber = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .acsReferenceNumber)
        } catch {
            self.acsReferenceNumber = nil
        }
        
        do {
            self.acsSignedContent = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .acsSignedContent)
        } catch {
            self.acsSignedContent = nil
        }
        
        do {
            self.base64EncodedCReq = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .base64EncodedCReq)
        } catch {
            self.base64EncodedCReq = nil
        }
        
        do {
            self.acsURL = try threeDSTwoConfigContainer.decodeIfPresent(String.self, forKey: .acsURL)
        } catch {
            self.acsURL = nil
        }
    }
}
