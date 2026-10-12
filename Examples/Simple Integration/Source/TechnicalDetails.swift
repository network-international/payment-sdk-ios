//
//  TechnicalDetails.swift
//  Simple Integration
//
//  "Technical details" behind a failed payment: the error and the gateway's full responses, as
//  text a tester can read on the device and share.
//
//  "Your Payment could not be completed." is right for a shopper and useless for whoever has to
//  fix it — a gateway 422 carries its reason in the body. Everything here is redacted before it
//  is shown, because a shared report leaves the device: bearer tokens, card tokens, wallet
//  payloads and anything that looks like a card number are replaced.
//

import UIKit
import NISdk

enum TechnicalDetails {
    /// The raw body of the last create-order response, for the report's "Order" section.
    static var lastOrderResponseBody: String?

    /// The report for a failure in `flow`, built from the SDK's recent HTTP exchanges.
    static func report(flow: String,
                       status: String? = nil,
                       message: String? = nil,
                       paymentError: NIPaymentError? = nil,
                       error: Error? = nil,
                       orderReference: String? = nil) -> String {
        var lines: [String] = []
        lines.append("N-Genius payment — technical details")
        lines.append("Time: \(ISO8601DateFormatter().string(from: Date()))")
        lines.append("Flow: \(flow)")
        if let status = status { lines.append("Status: \(status)") }
        lines.append("Platform: iOS \(UIDevice.current.systemVersion) · SDK \(NISdk.sharedInstance.version)")
        if let env = selectedEnvironment() {
            // Never the API key.
            lines.append("Environment: \(env.nickname) (\(env.type.rawValue)) · outlet \(env.outletReference) · \(env.region.rawValue) · \(env.currency)")
        }
        if let ref = orderReference { lines.append("Order reference: \(ref)") }
        if let message = message { lines.append("Shown to shopper: \(message)") }

        if let paymentError = paymentError {
            lines.append("")
            lines.append("Error")
            lines.append("  category: \(paymentError.category.rawVal)")
            lines.append("  method: \(paymentError.paymentMethod ?? "-")")
            lines.append("  message: \(redact(text: paymentError.message ?? "-"))")
        }
        if let error = error {
            let ns = error as NSError
            lines.append("")
            lines.append("Error")
            lines.append("  domain: \(ns.domain)")
            lines.append("  code: \(ns.code)")
            lines.append("  description: \(redact(text: ns.localizedDescription))")
            if let raw = ns.userInfo[rawResponseKey] as? String {
                lines.append("")
                lines.append("Response")
                lines.append(pretty(raw))
            }
        }

        let exchanges = NISdk.sharedInstance.recentHttpExchanges
        if let failed = exchanges.last(where: { $0.statusCode >= 400 || $0.errorDescription != nil }) {
            lines.append("")
            lines.append("Failed call")
            lines.append(contentsOf: describe(failed))
        }
        if !exchanges.isEmpty {
            lines.append("")
            lines.append("SDK calls for this payment (\(exchanges.count), oldest first)")
            for exchange in exchanges {
                lines.append("")
                lines.append(contentsOf: describe(exchange))
            }
        }

        if let order = lastOrderResponseBody {
            lines.append("")
            lines.append("Order")
            lines.append(pretty(order))
        }
        return lines.joined(separator: "\n")
    }

    /// `NSError.userInfo` key under which the demo's own API calls keep the server's raw body.
    static let rawResponseKey = "TechnicalDetailsRawResponse"

    private static func selectedEnvironment() -> Environment? {
        guard let id = Environment.getSelectedEnvironment() else { return nil }
        return Environment.getEnvironments().first { $0.id == id }
    }

    private static func describe(_ exchange: NIHttpExchange) -> [String] {
        var lines = ["\(exchange.method) \(redact(text: exchange.url))",
                     exchange.statusCode == 0 ? "No response" : "HTTP \(exchange.statusCode)"]
        if let error = exchange.errorDescription { lines.append("Error: \(error)") }
        lines.append(exchange.responseBody.map(pretty) ?? "(no response body)")
        return lines
    }

    // MARK: - Redaction

    /// Keys whose values must never leave the device, compared lower-cased.
    private static let secretKeys: Set<String> = [
        "$accesstoken", "accesstoken", "access_token", "refresh_token", "token", "cardtoken",
        "authorization", "apikey", "password", "cvv", "csc", "pan", "cardnumber",
        "paymentdata", "encryptedobj", "signature",
    ]

    /// `body` pretty-printed and redacted when it is JSON, redacted as text otherwise.
    static func pretty(_ body: String) -> String {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
              json is [String: Any] || json is [Any],
              let out = try? JSONSerialization.data(withJSONObject: redact(json: json),
                                                    options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
              let text = String(data: out, encoding: .utf8) else {
            return redact(text: body)
        }
        return text
    }

    static func redact(json: Any) -> Any {
        if let dict = json as? [String: Any] {
            var out: [String: Any] = [:]
            for (key, value) in dict {
                out[key] = secretKeys.contains(key.lowercased()) ? "[redacted]" : redact(json: value)
            }
            return out
        }
        if let array = json as? [Any] { return array.map(redact(json:)) }
        if let string = json as? String { return redact(text: string) }
        return json
    }

    /// Pay-page links carry a one-time `code`, and a card number can turn up in free text;
    /// neither belongs in a shared report.
    static func redact(text: String) -> String {
        var result = text
        if let query = try? NSRegularExpression(pattern: "([?&](?:code|access_token|token)=)[^&\\s\"]+") {
            result = query.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result),
                                                    withTemplate: "$1[redacted]")
        }
        if let digits = try? NSRegularExpression(pattern: "\\b\\d{13,19}\\b") {
            for match in digits.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
                guard let range = Range(match.range, in: result), luhn(String(result[range])) else { continue }
                result.replaceSubrange(range, with: "[card number redacted]")
            }
        }
        return result
    }

    private static func luhn(_ digits: String) -> Bool {
        var sum = 0
        for (i, char) in digits.reversed().enumerated() {
            guard var n = char.wholeNumberValue else { return false }
            if i % 2 == 1 {
                n *= 2
                if n > 9 { n -= 9 }
            }
            sum += n
        }
        return sum % 10 == 0
    }
}

/// Full-screen, selectable view of a report with Copy and Share.
final class TechnicalDetailsViewController: UIViewController {
    private let report: String

    init(report: String) {
        self.report = report
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Presents the report over `presenter` in its own navigation bar.
    static func present(_ report: String, from presenter: UIViewController) {
        let nav = UINavigationController(rootViewController: TechnicalDetailsViewController(report: report))
        presenter.present(nav, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Technical details"
        view.backgroundColor = .systemBackground

        let textView = UITextView()
        textView.text = report
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        // Report text is machine output; keep it left-to-right in Arabic too.
        textView.semanticContentAttribute = .forceLeftToRight
        textView.textAlignment = .left
        textView.accessibilityIdentifier = "techdetails_text_report"
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let close = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        close.accessibilityIdentifier = "techdetails_button_close"
        let share = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped(_:)))
        share.accessibilityIdentifier = "techdetails_button_share"
        share.accessibilityLabel = "Share"
        let copy = UIBarButtonItem(image: UIImage(systemName: "doc.on.doc"), style: .plain,
                                   target: self, action: #selector(copyTapped))
        copy.accessibilityIdentifier = "techdetails_button_copy"
        copy.accessibilityLabel = "Copy"
        navigationItem.leftBarButtonItem = close
        navigationItem.rightBarButtonItems = [share, copy]
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func copyTapped() {
        UIPasteboard.general.string = report
        let alert = UIAlertController(title: nil, message: "Copied", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { alert.dismiss(animated: true) }
    }

    @objc private func shareTapped(_ sender: UIBarButtonItem) {
        let activity = UIActivityViewController(activityItems: [report], applicationActivities: nil)
        // iPad presents this as a popover, which crashes without an anchor.
        activity.popoverPresentationController?.barButtonItem = sender
        present(activity, animated: true)
    }
}

extension UIAlertController {
    /// Adds a "Technical details" button that opens the report `details` builds — built on tap,
    /// so it includes everything the SDK reported by then.
    func addTechnicalDetailsAction(presenter: UIViewController, details: @escaping () -> String) {
        // UIAlertAction has no accessibilityIdentifier; UI tests find it by its label.
        addAction(UIAlertAction(title: "Technical details", style: .default) { [weak presenter] _ in
            guard let presenter = presenter else { return }
            TechnicalDetailsViewController.present(details(), from: presenter)
        })
    }
}
