import Foundation
import OSLog

/// A lightweight wrapper for unified logging.
/// Usage: Logger.info("Message"), Logger.error("Error: \(error)")
enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.grock.app"
    
    // Categorized logs for better filtering in Console.app
    private static let general = OSLog(subsystem: subsystem, category: "General")
    private static let vault = OSLog(subsystem: subsystem, category: "VaultService")
    private static let cart = OSLog(subsystem: subsystem, category: "Cart")
    private static let ui = OSLog(subsystem: subsystem, category: "UI")
    
    // MARK: - Logging Methods
    
    static func debug(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        log(message, type: .debug, category: category)
        #endif
    }
    
    static func info(_ message: String, category: LogCategory = .general) {
        log(message, type: .info, category: category)
    }
    
    static func warning(_ message: String, category: LogCategory = .general) {
        log("⚠️ \(message)", type: .default, category: category)
    }
    
    static func error(_ message: String, category: LogCategory = .general) {
        log("❌ \(message)", type: .error, category: category)
    }
    
    private static func log(_ message: String, type: OSLogType, category: LogCategory) {
        let logObject: OSLog
        switch category {
        case .general: logObject = general
        case .vault: logObject = vault
        case .cart: logObject = cart
        case .ui: logObject = ui
        }
        
        os_log("%{public}@", log: logObject, type: type, message)
    }
}

enum LogCategory {
    case general
    case vault
    case cart
    case ui
}
