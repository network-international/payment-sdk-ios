//
//  HttpClient.swift
//  NISdk
//
//  Created by Johnny Peter on 09/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import os.log

public enum HTTPClientErrors: Error {
    case missingUrl
}

public typealias HttpResponseCallback = (Data?, URLResponse?, Error?) -> Void

public class HTTPClient {
    let session: URLSession
    let request: NSMutableURLRequest

    public init?(url: String) {
        if let url = URL(string: url) {
            self.session = URLSession(configuration: URLSessionConfiguration.default)
            self.request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
            self.request.httpMethod = "GET" // default value
        } else {
            os_log("[NISdk] HTTPClient init failed — invalid URL: %{public}@", log: NISdkLogger.network, type: .error, url)
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
        let method = request.httpMethod ?? "GET"
        let urlString = request.url?.absoluteString ?? "unknown"
        os_log("[NISdk] --> %{public}@ %{public}@", log: NISdkLogger.network, type: .debug, method, urlString)

        // In verbose mode record the full exchange — headers and bodies — so a failing
        // call can be diagnosed from the log alone, without a proxy on the device.
        if NISdkLogger.verboseDiagnosticsEnabled {
            NISdkLogger.trace("--> \(method) \(urlString)")
            NISdkLogger.trace("    headers: \(NISdkLogger.redactedHeaders(request.allHTTPHeaderFields))")
            NISdkLogger.trace("    body: \(NISdkLogger.bodyPreview(request.httpBody))")
        }

        let startedAt = CFAbsoluteTimeGetCurrent()
        let task = session.dataTask(with: self.request as URLRequest) { data, response, error in
            let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - startedAt) * 1000)
            if let error = error {
                os_log("[NISdk] <-- %{public}@ %{public}@ ERROR: %{public}@", log: NISdkLogger.network, type: .error, method, urlString, error.localizedDescription)
                if NISdkLogger.verboseDiagnosticsEnabled {
                    let ns = error as NSError
                    NISdkLogger.trace("<-- \(method) \(urlString) TRANSPORT ERROR after \(elapsedMs)ms")
                    NISdkLogger.trace("    \(ns.domain) code \(ns.code): \(ns.localizedDescription)")
                }
            } else if let http = response as? HTTPURLResponse {
                let corrId = http.allHeaderFields.first(where: { ($0.key as? String)?.lowercased() == "x-correlation-id" })?.value as? String ?? ""
                os_log("[NISdk] <-- %{public}@ %{public}@ %d X-Correlation-Id: %{public}@", log: NISdkLogger.network, type: .debug, method, urlString, http.statusCode, corrId)
                if NISdkLogger.verboseDiagnosticsEnabled {
                    let headers = Dictionary(uniqueKeysWithValues: http.allHeaderFields.compactMap {
                        key, value -> (String, String)? in
                        guard let key = key as? String else { return nil }
                        return (key, String(describing: value))
                    })
                    NISdkLogger.trace("<-- \(method) \(urlString) HTTP \(http.statusCode) in \(elapsedMs)ms")
                    NISdkLogger.trace("    headers: \(NISdkLogger.redactedHeaders(headers))")
                    NISdkLogger.trace("    body: \(NISdkLogger.bodyPreview(data))")
                }
            } else if NISdkLogger.verboseDiagnosticsEnabled {
                NISdkLogger.trace("<-- \(method) \(urlString) completed after \(elapsedMs)ms with no HTTP response and no error")
            }
            completionHandler(data, response, error)
        }
        task.resume()
    }
}
