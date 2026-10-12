//
//  HttpClient.swift
//  NISdk
//
//  Created by Johnny Peter on 09/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import UIKit

public enum HTTPClientErrors: Error {
    case missingUrl
}

public typealias HttpResponseCallback = (Data?, URLResponse?, Error?) -> Void

public class HTTPClient {
    /// The session every client uses unless one is passed explicitly.
    ///
    /// Tests swap this for a session whose configuration carries a stub `URLProtocol`. An
    /// `.ephemeral` configuration ignores `URLProtocol.registerClass`, so without this hook there
    /// is no way to exercise the transaction service without real network calls.
    static var sharedSession = URLSession(configuration: .ephemeral)

    let session: URLSession
    let request: NSMutableURLRequest

    public init?(url: String, session: URLSession? = nil) {
        if let url = URL(string: url) {
            self.session = session ?? HTTPClient.sharedSession
            self.request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
            self.request.httpMethod = "GET" // default value
        } else {
            print("Invalid url")
            return nil
        }
    }
    
    public func withMethod(method: String) -> HTTPClient {
        request.httpMethod = method
        return self
    }
    
    public func withHeaders(headers: [String: String]) -> HTTPClient {
        for(key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.addValue("iOS pay page \(UIDevice().name) \(UIDevice().systemName)-\(UIDevice().systemVersion) - SDK -\(NISdk.sharedInstance.version)", forHTTPHeaderField: "User-Agent")
        request.addValue(NISdk.sharedInstance.platform.headerValue, forHTTPHeaderField: "X-NI-Platform")
        return self
    }
    
    public func withBodyData(data: Data) -> HTTPClient {
        request.httpBody = data
        return self
    }
    
    public func withBodyData(data: String) -> HTTPClient {
        request.httpBody = data.data(using: .utf8)
        return self
    }
    
    public func withQueryParams(queries: [String: String]) -> HTTPClient {
        if queries.isEmpty {
            return self
        }
        guard var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: true) else {
            return self
        }
        let queryItems: [URLQueryItem] = queries.map { key, value in
            return URLQueryItem(name: key, value: value)
        }
        
        components.queryItems = (components.queryItems ?? []) + queryItems
        request.url = components.url
        return self
    }
    
    public func makeRequest(with completionHandler: @escaping (HttpResponseCallback)) {
        let urlRequest = self.request as URLRequest
        let startTime = Date()

        NILogger.shared.logRequest(urlRequest)

        let task = session.dataTask(with: urlRequest) { data, response, error in
            let elapsed = Date().timeIntervalSince(startTime)
            if let error = error {
                NILogger.shared.logError(error, elapsed: elapsed)
            } else {
                NILogger.shared.logResponse(response, data: data, elapsed: elapsed)
            }
            NIHttpExchangeLog.record(request: urlRequest, response: response, data: data, error: error)
            completionHandler(data, response, error)
        }
        task.resume()
    }
}

/// One HTTP call the SDK made, kept so an app can show what the gateway actually answered when a
/// payment fails — `PaymentStatus.PaymentFailed` alone hides a 422's `errors[0].errorCode`.
///
/// Request bodies are deliberately not kept: they carry card numbers, CVVs and wallet tokens.
/// Response bodies are kept as received, so an app that shows or shares them must redact.
@objc public final class NIHttpExchange: NSObject {
    @objc public let date: Date
    @objc public let method: String
    @objc public let url: String
    /// 0 when no response arrived.
    @objc public let statusCode: Int
    @objc public let responseBody: String?
    @objc public let errorDescription: String?

    init(date: Date, method: String, url: String, statusCode: Int,
         responseBody: String?, errorDescription: String?) {
        self.date = date
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.responseBody = responseBody
        self.errorDescription = errorDescription
    }
}

/// The last few exchanges, newest last. Bounded so a long session cannot grow it without limit.
enum NIHttpExchangeLog {
    private static let lock = NSLock()
    private static var entries: [NIHttpExchange] = []
    private static let capacity = 20
    private static let maxBodyLength = 256 * 1024

    static func record(request: URLRequest, response: URLResponse?, data: Data?, error: Error?) {
        var body = data.flatMap { String(data: $0, encoding: .utf8) }
        if let text = body, text.count > maxBodyLength {
            body = String(text.prefix(maxBodyLength)) + "\n…[truncated]"
        }
        let exchange = NIHttpExchange(
            date: Date(),
            method: request.httpMethod ?? "GET",
            url: request.url?.absoluteString ?? "",
            statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
            responseBody: body,
            errorDescription: error?.localizedDescription)
        lock.lock()
        entries.append(exchange)
        if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
        lock.unlock()
    }

    static var all: [NIHttpExchange] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    static func clear() {
        lock.lock()
        entries.removeAll()
        lock.unlock()
    }
}
