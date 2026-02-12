//
//  ConfigServiceAdapter.swift
//  Pods
//
//  Created by Prasath R on 10/02/26.
//

import Foundation
import PassKit

@objc final class ConfigServiceAdapter: NSObject, ConfigService {
    
    func getInvoiceConfig(for url: String, using accessToken: String, with completion: @escaping HttpResponseCallback) {
        let orderRequestHeaders = ["Authorization": "Bearer \(accessToken)"]
        
        HTTPClient(url: url)?
            .withMethod(method: "GET")
            .withHeaders(headers: orderRequestHeaders)
            .makeRequest(with: completion)
    }
    
}
