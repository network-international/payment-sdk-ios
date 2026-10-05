import Foundation

/// One environment decoded from a QR payload line.
///
/// Line format, pipe-delimited, shared with the Android and Flutter demos and the
/// outlet-cred-puller:
///
///     nickname|realm|outletReference|apiKey|applePayMerchantId|region|currency|type|orderAction|orderType|paymentMethods
///
/// `paymentMethods` is comma-separated and informational — what the gateway offered on a
/// probe order, shown on the environment tile so an outlet's capabilities are visible
/// without opening it.
///
/// The first five fields are the original contract; the rest were appended as region,
/// currency, order action and order type each moved onto the outlet, so a five- or
/// eight-field code from an older generator still parses, defaulting whatever it omits.
/// The three- and four-field legacy shapes
/// (no nickname / no Apple Pay id) stay accepted: the Android demo takes them and older
/// codes are in circulation.
struct ScannedEnvironment: Identifiable, Equatable {
    let id = UUID()
    let nickname: String
    let realm: String
    let outletReference: String
    let apiKey: String
    let applePayMerchantId: String
    let region: Region
    let currency: String
    /// DEV / UAT / PROD. Present so a bulk import needs no per-outlet prompt.
    let type: EnvironmentType
    /// SALE / PURCHASE / AUTH; an omitted field means the default, SALE.
    let orderAction: String
    /// RECURRING / UNSCHEDULED / INSTALLMENT; empty means SINGLE.
    let orderType: String
    /// Gateway payment-method names. Empty for a code predating the field.
    let paymentMethods: [String]

    init(nickname: String, realm: String, outletReference: String, apiKey: String,
         applePayMerchantId: String = "", region: Region = .UAE, currency: String = "AED",
         type: EnvironmentType = .DEV, orderAction: String = "SALE", orderType: String = "",
         paymentMethods: [String] = []) {
        self.nickname = nickname
        self.realm = realm
        self.outletReference = outletReference
        self.apiKey = apiKey
        self.applePayMerchantId = applePayMerchantId
        self.region = region
        self.currency = currency
        self.type = type
        self.orderAction = orderAction
        self.orderType = orderType
        self.paymentMethods = paymentMethods
    }

    /// Everything parsed from a payload, plus how many lines were not an environment.
    struct Batch {
        let environments: [ScannedEnvironment]
        let rejected: Int
    }

    /// Parses one pipe-delimited line. Nil on an unrecognised shape.
    static func parse(_ line: String) -> ScannedEnvironment? {
        let parts = line.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        func at(_ i: Int, _ fallback: String = "") -> String {
            i < parts.count && !parts[i].isEmpty ? parts[i] : fallback
        }

        switch parts.count {
        case 5...:
            return ScannedEnvironment(
                nickname: at(0), realm: at(1), outletReference: at(2), apiKey: at(3),
                applePayMerchantId: at(4),
                region: Region(rawValue: at(5, "UAE").uppercased()) ?? .UAE,
                currency: at(6, "AED").uppercased(),
                type: EnvironmentType(rawValue: at(7, "DEV").uppercased()) ?? .DEV,
                orderAction: at(8, "SALE").uppercased(),
                // SINGLE is the empty string on the wire, so an explicit "SINGLE" is
                // normalised rather than stored as a value nothing would match.
                orderType: at(9).uppercased() == "SINGLE" ? "" : at(9).uppercased(),
                paymentMethods: at(10)
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
                    .filter { !$0.isEmpty })
        case 4:
            return ScannedEnvironment(nickname: at(0), realm: at(1), outletReference: at(2), apiKey: at(3))
        case 3:
            return ScannedEnvironment(nickname: "", realm: at(0), outletReference: at(1), apiKey: at(2))
        default:
            return nil
        }
    }

    /// Encodes one environment as a payload line — the inverse of [parse].
    ///
    /// Always writes all ten fields so a line never has a variable shape, and strips pipes
    /// and newlines from the free-text fields: the format has no escaping, so a pipe in a
    /// nickname would shift every later field and put the region where the API key belongs.
    static func encode(_ e: Environment) -> String {
        [
            e.nickname,
            e.realm,
            e.outletReference,
            e.apiKey,
            e.applePayMerchantId,
            e.region.rawValue,
            e.currency,
            e.type.rawValue,
            e.orderAction,
            // SINGLE is the empty string in the model; write it out so the line
            // always has ten fields.
            e.orderType.isEmpty ? "SINGLE" : e.orderType,
            e.paymentMethods.joined(separator: ","),
        ]
        .map { $0.replacingOccurrences(of: "[|\r\n]", with: " ", options: .regularExpression)
                 .trimmingCharacters(in: .whitespaces) }
        .joined(separator: "|")
    }

    /// Encodes every environment, one per line — what Copy and the QR both use.
    static func encodeAll(_ envs: [Environment]) -> String {
        envs.map(encode).joined(separator: "\n")
    }

    /// Splits `lines` into groups that each fit within `limitBytes` when joined.
    ///
    /// Whole lines only: an environment split across two codes would parse as two broken
    /// ones. A single line over the limit still gets a group of its own — dropping it would
    /// silently lose an outlet. The limit matches the outlet-cred-puller's, so a batch
    /// splits identically whichever end generates it.
    static func chunkLines(_ lines: [String], limitBytes: Int) -> [[String]] {
        var chunks: [[String]] = []
        var current: [String] = []
        var size = 0
        for line in lines {
            let add = line.utf8.count + (current.isEmpty ? 0 : 1)
            if !current.isEmpty && size + add > limitBytes {
                chunks.append(current)
                current = []
                size = 0
            }
            current.append(line)
            size += add
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks
    }

    /// Parses a whole payload: one environment per line, blank lines ignored. A bulk code
    /// with one bad line still imports the rest and reports what it skipped.
    static func parseAll(_ payload: String) -> Batch {
        var envs: [ScannedEnvironment] = []
        var rejected = 0
        for raw in payload.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if let e = parse(line) { envs.append(e) } else { rejected += 1 }
        }
        return Batch(environments: envs, rejected: rejected)
    }

    static func == (a: ScannedEnvironment, b: ScannedEnvironment) -> Bool {
        a.outletReference == b.outletReference && a.type == b.type
    }
}
