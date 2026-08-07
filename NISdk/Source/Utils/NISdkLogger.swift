import Foundation
import os.log

struct NISdkLogger {
    private static let subsystem = "com.ni.NISdk"

    static let sdk     = OSLog(subsystem: subsystem, category: "SDK")
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let payment = OSLog(subsystem: subsystem, category: "Payment")
    static let auth    = OSLog(subsystem: subsystem, category: "Authorization")
    static let aani    = OSLog(subsystem: subsystem, category: "Aani")

    // MARK: - File diagnostics
    //
    // os_log output cannot be read off a physical device without root (`log collect
    // --device-udid` fails with "Device not configured" on recent iOS). When the
    // NISDK_FILE_DIAGNOSTICS environment variable is set, mirror diagnostic lines into
    // Documents/nisdk-diagnostics.log, which can be retrieved with:
    //
    //   xcrun devicectl device copy from --device <udid> \
    //     --domain-type appDataContainer --domain-identifier <bundle-id> \
    //     --source Documents --destination <dir>
    //
    // Off unless the variable is present, so release builds are unaffected.
    //
    // An app can also switch this on for itself — without being launched from Xcode or
    // devicectl, which is the only way to set an environment variable — by adding a
    // boolean `NISdkVerboseDiagnostics` key to its Info.plist. That is what makes a
    // standalone "verbose build" possible.
    //
    // WARNING: verbose mode logs full request and response bodies (see HTTPClient).
    // Those carry payment data. It is a diagnostic aid, never a production setting.

    static let verboseDiagnosticsEnabled: Bool = {
        if ProcessInfo.processInfo.environment["NISDK_FILE_DIAGNOSTICS"] != nil { return true }
        if let flag = Bundle.main.object(forInfoDictionaryKey: "NISdkVerboseDiagnostics") as? Bool {
            return flag
        }
        return false
    }()

    private static var fileLoggingEnabled: Bool { verboseDiagnosticsEnabled }

    private static let queue = DispatchQueue(label: "com.ni.NISdk.diagnostics")

    private static let logFileURL: URL? = {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return dir.appendingPathComponent("nisdk-diagnostics.log")
    }()

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    /// Appends `message` to the on-device diagnostics file when file logging is enabled.
    /// Callers should still emit their normal os_log line; this is purely a retrievable mirror.
    static func trace(_ message: String) {
        guard fileLoggingEnabled, let url = logFileURL else { return }
        queue.async {
            let line = "\(timestampFormatter.string(from: Date())) \(message)\n"
            guard let data = line.data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
            } else {
                try? data.write(to: url)
            }
        }
    }

    /// Emits `message` to os_log **and** to the on-device diagnostics file, so a single
    /// call site produces both the Console.app line and the retrievable one.
    static func event(_ message: String,
                      log: OSLog = NISdkLogger.payment,
                      type: OSLogType = .info) {
        os_log("[NISdk] %{public}@", log: log, type: type, message)
        trace(message)
    }

    /// Writes a run separator so a diagnostics file spanning several attempts can be
    /// read one payment at a time. Only does anything in verbose mode.
    static func beginSession(_ label: String) {
        guard verboseDiagnosticsEnabled else { return }
        trace("──────── \(label) ────────")
        trace("NISdk \(NISdk.sharedInstance.version) · diagnostics file: \(logFileURL?.path ?? "unavailable")")
    }

    // MARK: - Formatting helpers

    /// Header dictionary rendered for logging, with credentials masked. Bearer tokens and
    /// cookies identify a live payment session, so only their length is recorded.
    static func redactedHeaders(_ headers: [String: String]?) -> String {
        guard let headers = headers, !headers.isEmpty else { return "none" }
        let sensitive = ["authorization", "cookie", "set-cookie", "proxy-authorization"]
        return headers
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .map { key, value in
                sensitive.contains(key.lowercased())
                    ? "\(key): <redacted, \(value.count) chars>"
                    : "\(key): \(value)"
            }
            .joined(separator: " | ")
    }

    /// UTF-8 preview of a body, truncated so a large response cannot flood the log.
    static func bodyPreview(_ data: Data?, limit: Int = 2000) -> String {
        guard let data = data else { return "<no body>" }
        if data.isEmpty { return "<empty body, 0 bytes>" }
        guard let text = String(data: data.prefix(limit), encoding: .utf8) else {
            return "<non-utf8 body, \(data.count) bytes>"
        }
        return data.count > limit
            ? "\(text)… (truncated, \(data.count) bytes total)"
            : text
    }
}
