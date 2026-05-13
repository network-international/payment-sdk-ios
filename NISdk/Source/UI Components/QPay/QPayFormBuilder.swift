//
//  QPayFormBuilder.swift
//  NISdk
//

import Foundation

enum QPayFormBuilder {

    /// QCB gateway URLs sometimes carry visually-identical Unicode dashes (U+2010..U+2015, U+2212, U+FE58)
    /// that the gateway rejects. Mirrors PayPageV2's `normalizeQPayRedirectUri`.
    private static let unicodeDashes: Set<Character> = [
        "\u{2010}", "\u{2011}", "\u{2012}", "\u{2013}", "\u{2014}", "\u{2015}",
        "\u{2212}", "\u{FE58}"
    ]

    static func normalizeRedirectUri(_ uri: String) -> String {
        return String(uri.map { unicodeDashes.contains($0) ? "-" : $0 })
    }

    /// Builds the auto-submitting HTML form. Returns nil if `redirectUri` is missing.
    static func buildAutoSubmitHTML(response: QPayInitResponse) -> String? {
        guard let raw = response.redirectUri, !raw.isEmpty else { return nil }
        let action = htmlEscape(normalizeRedirectUri(raw))

        let inputs = response.orderedFormFields.map { field -> String in
            let name = htmlEscape(field.name)
            let value = htmlEscape(field.value)
            return "<input type=\"hidden\" name=\"\(name)\" value=\"\(value)\" />"
        }.joined(separator: "\n    ")

        return """
        <!DOCTYPE html>
        <html>
          <head><meta charset="utf-8"><title>QPay</title></head>
          <body>
            <form id="QPayRedirectForm" method="post" action="\(action)">
            \(inputs)
            </form>
            <script>document.getElementById('QPayRedirectForm').submit();</script>
          </body>
        </html>
        """
    }

    /// Builds a URL-encoded body for direct `URLRequest` POST. Bypasses HTML parsing entirely.
    /// Returns nil if `redirectUri` is missing.
    static func buildPOSTRequest(response: QPayInitResponse) -> URLRequest? {
        guard let raw = response.redirectUri, !raw.isEmpty,
              let url = URL(string: normalizeRedirectUri(raw)) else { return nil }

        let body = response.orderedFormFields.map { field -> String in
            "\(percentEncode(field.name))=\(percentEncode(field.value))"
        }.joined(separator: "&")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(url.absoluteString, forHTTPHeaderField: "Referer")
        request.httpBody = body.data(using: .utf8)
        return request
    }

    private static func percentEncode(_ s: String) -> String {
        // application/x-www-form-urlencoded — encode all non-alphanumerics, then swap %20 for +.
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "*-._")
        return s.addingPercentEncoding(withAllowedCharacters: allowed)?
            .replacingOccurrences(of: "%20", with: "+") ?? s
    }

    private static func htmlEscape(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: "&", with: "&amp;")
        out = out.replacingOccurrences(of: "<", with: "&lt;")
        out = out.replacingOccurrences(of: ">", with: "&gt;")
        out = out.replacingOccurrences(of: "\"", with: "&quot;")
        out = out.replacingOccurrences(of: "'", with: "&#39;")
        return out
    }
}
