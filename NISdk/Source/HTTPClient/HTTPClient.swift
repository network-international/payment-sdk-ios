//
//  HttpClient.swift
//  NISdk
//
//  Created by Johnny Peter on 09/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

public enum HTTPClientErrors: Error {
    case missingUrl
}

public class HTTPClient {
    let session = URLSession.shared
    public var url: URL?
    
    public init() {}
    
    public func with(url: String) -> HTTPClient {
        self.url = URL(string: url)
        return self;
    }
    
    public func makeRequest(with completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        if let url = self.url {
            let request = session.dataTask(with: url, completionHandler: completionHandler)
            request.resume()
        } else {
            completionHandler(nil, nil, HTTPClientErrors.missingUrl);
        }
    }
}
