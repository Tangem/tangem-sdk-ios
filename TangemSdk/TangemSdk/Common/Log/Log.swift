//
//  Log.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 05.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

private let logger = Log()

public class Log {
    public static var config: Log.Config = .verbose {
        didSet {
            logger.logLevel = config.logLevel
            logger.loggers = config.loggers
        }
    }
    
    private(set) var logLevel: [Log.Level] = []
    
    private(set) var loggers: [TangemSdkLogger] = []
    
    public static func warning<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .warning)
    }
    
    public static func error<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .error)
    }
    
    public static func nfc<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .nfc)
    }
    
    public static func apdu<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .apdu)
    }
    
    public static func command<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .command)
    }
    
    public static func session<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .session)
    }
    
    public static func tlv<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .tlv)
    }
    
    public static func debug<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .debug)
    }
    
    public static func network<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .network)
    }
    
    public static func view<T>(_ message: @autoclosure () -> T) {
        logger.logInternal(message(), level: .view)
    }
    
    public static func filter(_ level: Log.Level) -> Bool {
       return logger.logLevel.contains(level)
    }
    
    private func logInternal<T>(_ message: @autoclosure () -> T, level: Log.Level) {
        guard !loggers.isEmpty else { return }
        
        let msg = String(describing: message())
        for logger in loggers {
            logger.log(msg, level: level)
        }
    }
}

public extension Log {
    enum Level: CaseIterable {
        case command
        case tlv
        case apdu
        case session
        case nfc
        case warning
        case error
        case debug
        case network
        case view
        
        var emoji: String {
            switch self {
            case .command:
                return "⚪️"
            case .session:
                return "🟡"
            case .tlv:
                return "🟣"
            case .apdu:
                return "🟢"
            case .nfc:
                return "🔵"
            case .warning:
                return "⚠️"
            case .error:
                return "❌"
            case .debug:
                return "🪲"
            case .network:
                return "🟠"
            case .view:
                return "🟤"
            }
        }
        
        var prefix: String {
            switch self {
            case .session:
                return " (CardSession)"
            case .nfc:
                return " (NFCReader)"
            case .view:
                return " (ViewDelegate)"
            default:
                return ""
            }
        }
    }
}

public extension Log {
    enum Config {
        case release
        case debug
        case verbose
        case custom(logLevel: [Log.Level],
                    loggers: [TangemSdkLogger] = [ConsoleLogger()])
        
        internal var logLevel: [Log.Level] {
            switch self {
            case .custom(let logLevel, _):
                return logLevel
            case .debug:
                return [.warning, .error]
            case .release:
                return [.error]
            case .verbose:
                return Log.Level.allCases
            }
        }
        
        internal var loggers: [TangemSdkLogger] {
            switch self {
            case .custom(_, let loggers):
                return loggers
            default:
                return [ConsoleLogger()]
            }
        }
    }
}
// MARK:- Log formatter helpers
@available(iOS 13.0, *)
extension Log {
    static func sendCommand(_ commandObject: AnyObject) {
        let commandName = "\(commandObject)".remove("TangemSdk.").remove("Command")
        let separator = Array(repeating: "=", count: 64).joined()
        logger.logInternal(separator, level: .command)
        command("Send command: \(commandName)".titleFormatted)
        logger.logInternal(separator, level: .command)
    }
}
