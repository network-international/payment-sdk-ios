//
//  Logger.swift
//  NISdk
//
//  Copyright © 2024 Network International. All rights reserved.
//

import Foundation
import os

class NILogger {
    static let shared = NILogger()

    var isEnabled = false

    private let subsystem = "com.ni.sdk"
    private let category = "API"
    private let maxBodyLogLength = 1024

    private let sensitiveHeaders: Set<String> = [
        "authorization",
        "cookie",
        "set-cookie",
        "payment-token"
    ]

    private init() {}

    func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }

        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"

        log("➡️ REQUEST: \(method) \(url)")

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            let maskedHeaders = headers.map { key, value in
                "\(key): \(maskHeaderValue(key: key, value: value))"
            }.joined(separator: ", ")
            log("  Headers: \(maskedHeaders)")
        }

        if let body = request.httpBody {
            let bodyString = String(data: body, encoding: .utf8) ?? "<binary data>"
            let truncated = truncateBody(bodyString)
            log("  Body: (\(body.count) bytes) \(truncated)")
        }
    }

    func logResponse(_ response: URLResponse?, data: Data?, elapsed: TimeInterval) {
        guard isEnabled else { return }

        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        let method = httpResponse?.url?.absoluteString ?? "unknown"
        let elapsedStr = String(format: "%.3f", elapsed)

        log("⬅️ RESPONSE: \(statusCode) (\(elapsedStr)s) \(method)")

        if let data = data {
            let bodyString = String(data: data, encoding: .utf8) ?? "<binary data>"
            let truncated = truncateBody(bodyString)
            log("  Body: (\(data.count) bytes) \(truncated)")
        }
    }

    func logError(_ error: Error, elapsed: TimeInterval) {
        guard isEnabled else { return }

        let elapsedStr = String(format: "%.3f", elapsed)
        log("❌ ERROR: \(error.localizedDescription) (\(elapsedStr)s)")
    }

    private func log(_ message: String) {
        let formatted = "[NISdk] \(message)"
        if #available(iOS 12.0, *) {
            let osLog = OSLog(subsystem: subsystem, category: category)
            os_log("%{public}@", log: osLog, type: .info, formatted)
        } else {
            print(formatted)
        }
    }

    private func maskHeaderValue(key: String, value: String) -> String {
        guard sensitiveHeaders.contains(key.lowercased()) else {
            return value
        }
        if key.lowercased() == "authorization" && value.count > 10 {
            return String(value.prefix(10)) + "..."
        }
        return "***"
    }

    private func truncateBody(_ body: String) -> String {
        if body.count > maxBodyLogLength {
            return String(body.prefix(maxBodyLogLength)) + " [truncated]"
        }
        return body
    }
}
