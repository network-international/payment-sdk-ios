//
//  URL+QueryParams.swift
//  NISdk
//
//  Created by Johnny Peter on 19/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension URL {
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}

/// Parameters that are the SDK's own, describe no one, and are the whole point of reading these
/// logs: which return leg a redirect was, and which method it belonged to.
private let loggableQueryParams: Set<String> = ["ni_sdk_result", "payment_method"]

extension URL {
    /// The URL rendered safe to write to the device log.
    ///
    /// The payment flows log every hop their WebView takes, and payment URLs carry credentials in
    /// their query string: the paypage's `code` is a live authorisation code for the order, and the
    /// providers append their own references and tokens on the way back. The device log is readable
    /// over the Console and survives in sysdiagnose archives.
    ///
    /// Scheme, host and path are kept — they are what makes a log useful — and the query string is
    /// dropped except for the parameters named above. The allowlist is the point: a denylist would
    /// keep whatever parameter a provider decides to add next.
    var redactedForLog: String {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return "<unparseable>"
        }
        // An opaque URL (mailto:, tel:, a provider's app link) keeps everything after the scheme in
        // one undelimited part, so there is no host to keep and nothing safe to assume about the rest.
        guard let host = components.host, !host.isEmpty else {
            return "\(components.scheme ?? ""):<opaque>"
        }

        var base = ""
        if let scheme = components.scheme { base += "\(scheme)://" }
        base += host
        if let port = components.port { base += ":\(port)" }
        base += components.path

        let items = components.queryItems ?? []
        if items.isEmpty { return base }

        let allowed = items.filter { loggableQueryParams.contains($0.name) }
        let kept = allowed.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
        let redacted = items.count - allowed.count

        var out = base
        if !kept.isEmpty { out += "?\(kept)" }
        if redacted > 0 { out += " (+\(redacted) redacted)" }
        return out
    }
}

/// See `URL.redactedForLog`. Takes the optional directly so call sites stay one expression.
func redactUrlForLog(_ url: URL?) -> String {
    guard let url = url else { return "<none>" }
    return url.redactedForLog
}

/// See `URL.redactedForLog`, for the call sites that hold a URL as a string.
func redactUrlForLog(_ url: String?) -> String {
    guard let url = url, !url.isEmpty else { return "<none>" }
    guard let parsed = URL(string: url) else { return "<unparseable>" }
    return parsed.redactedForLog
}
