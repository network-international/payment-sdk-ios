//
//  URLResponse+StatusCode.swift
//  NISdk
//
//  Created by Johnny Peter on 23/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension URLResponse {
    func getStatusCode() -> Int? {
        if let httpResponse = self as? HTTPURLResponse {
            return httpResponse.statusCode
        } else {
            return nil
        }
    }
    
    func getResponseHeaders() -> [AnyHashable:Any]? {
        if let httpURLResponse = self as? HTTPURLResponse {
            return httpURLResponse.allHeaderFields
        } else {
            return nil
        }
    }
    
    func isSuccess() -> Bool {
        if let statusCode = self.getStatusCode() {
            if(statusCode < 200 || statusCode > 299) {
                return true
            }
        }
        return false
    }
}
