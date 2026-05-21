import os.log

struct NISdkLogger {
    private static let subsystem = "com.ni.NISdk"

    static let sdk     = OSLog(subsystem: subsystem, category: "SDK")
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let payment = OSLog(subsystem: subsystem, category: "Payment")
    static let auth    = OSLog(subsystem: subsystem, category: "Authorization")
    static let aani    = OSLog(subsystem: subsystem, category: "Aani")
}
