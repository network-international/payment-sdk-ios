import Foundation

/// One environment decoded from a QR payload line.
///
/// Line format, pipe-delimited, shared with the Android and Flutter demos and the
/// outlet-cred-puller:
///
///     nickname|realm|outletReference|apiKey|applePayMerchantId|region|currency|type|orderAction|orderType
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

    init(nickname: String, realm: String, outletReference: String, apiKey: String,
         applePayMerchantId: String = "", region: Region = .UAE, currency: String = "AED",
         type: EnvironmentType = .DEV, orderAction: String = "SALE", orderType: String = "") {
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
                orderType: at(9).uppercased() == "SINGLE" ? "" : at(9).uppercased())
        case 4:
            return ScannedEnvironment(nickname: at(0), realm: at(1), outletReference: at(2), apiKey: at(3))
        case 3:
            return ScannedEnvironment(nickname: "", realm: at(0), outletReference: at(1), apiKey: at(2))
        default:
            return nil
        }
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
