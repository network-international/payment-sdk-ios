//
//  HTTPStubs.swift
//  UIHostAppUITests
//
//  Created by Niraj Chauhan on 5/9/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import Swifter

enum HTTPMethod {
    case POST
    case GET
    case PUT
}

struct HTTPStubInfo {
    let url: String
    let jsonFilename: String
    let method: HTTPMethod
}

let initialStubs = [
    HTTPStubInfo(url: "api/create_payment_order", jsonFilename: "order_create", method: .POST),
    HTTPStubInfo(url: "/paymentAuthorizationUrl", jsonFilename: "payment_auth", method: .POST),
    HTTPStubInfo(url: "/transactions/outlets/outletId/orders/orderId", jsonFilename: "order", method: .GET),
    HTTPStubInfo(url: "/transactions/outlets/outletId/orders/orderId/payments/paymentId/card", jsonFilename: "card_payment", method: .PUT)
]

class HTTPStubs {
    
    var server = HttpServer()
    
    func setUp() {
        setupInitialStubs()
        try! server.start(3000)
    }
    
    func tearDown() {
        server.stop()
    }
    
    func setupInitialStubs() {
        // Setting up all the initial mocks from the array
        for stub in initialStubs {
            setupStub(url: stub.url, filename: stub.jsonFilename, method: stub.method)
        }
    }
    
    public func setupStub(url: String, filename: String, method: HTTPMethod = .GET) {
        let testBundle = Bundle(for: type(of: self))
        let filePath = testBundle.path(forResource: filename, ofType: "json")
        let fileUrl = URL(fileURLWithPath: filePath!)
        let data = try! Data(contentsOf: fileUrl, options: .uncached)
        // Looking for a file and converting it to JSON        
        
        // Swifter makes it very easy to create stubbed responses
        let response: ((HttpRequest) -> HttpResponse) = { _ in
            return HttpResponse.raw(200, "OK", ["Set-Cookie" : "payment xyz"]) { (responseWriter) in
                try! responseWriter.write(data)
            }
        }
        
        switch method  {
            case .GET : server.GET[url] = response
            case .POST: server.POST[url] = response
            case .PUT: server.PUT[url] = response
        }
    }
    
    func dataToJSON(data: Data) -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        } catch let myJSONError {
            print(myJSONError)
        }
        return nil
    }
}
