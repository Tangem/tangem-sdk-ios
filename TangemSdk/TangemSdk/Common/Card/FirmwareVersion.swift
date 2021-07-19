//
//  FirmwareVersion.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Holds information about card firmware version included version saved on card `version`,
/// splitted to `major`, `minor` and `patch` and `FirmwareType`
@available(iOS 13.0, *)
public struct FirmwareVersion: Codable {
    /// Version that saved on card
    public let stringValue: String
    
    public var doubleValue: Double {
        Double("\(major).\(minor)")!
    }
    
    private(set) public var major: Int = 0
    private(set) public var minor: Int = 0
    private(set) public var patch: Int = 0
    private(set) public var type: FirmwareType
    
    public init(stringValue: String) {
        self.stringValue = stringValue
        
        let versionCleaned = stringValue.remove("\0")
        
        let cardTypeStr = versionCleaned.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789."))
        let result = versionCleaned.remove(cardTypeStr)
        
        var splitted = result.split(separator: ".")
        if let majorStr = splitted.first, let major = Int(majorStr) {
            self.major = major
            splitted.removeFirst()
        }
        
        if let minorStr = splitted.first, let minor = Int(minorStr) {
            self.minor = minor
            splitted.removeFirst()
        }
        
        if let patchStr = splitted.first, let patch = Int(patchStr) {
            self.patch = patch
        }
        
        type = .type(for: cardTypeStr)
    }
    
    public init(major: Int, minor: Int, patch: Int = 0, type: FirmwareType = .sdk) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.type = type
        
        let patchSuffix = ".\(patch)"
        var version = "\(major).\(minor)"
        version += patch != 0 ? patchSuffix : ""
        version += type.rawValue
        
        self.stringValue = version
    }
}

@available(iOS 13.0, *)
extension FirmwareVersion: Comparable {
    public static func < (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        } else {
            return lhs.patch < rhs.patch
        }
    }
    
    public static func == (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
        lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
    
    public static func >= (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major > rhs.major
        } else if lhs.minor != rhs.minor {
            return lhs.minor > rhs.minor
        } else {
            return lhs.patch >= rhs.patch
        }
    }
    
    public static func < (lhs: FirmwareVersion?, rhs: FirmwareVersion) -> Bool {
        guard let lhs = lhs else { return false }
        
        return lhs < rhs
    }
    
    public static func >= (lhs: FirmwareVersion?, rhs: FirmwareVersion) -> Bool {
        guard let lhs = lhs else { return false }
        
        return lhs >= rhs
    }
    
}
//MARK: - Constants
@available(iOS 13.0, *)
public extension FirmwareVersion {
    /// Multi-wallet
    static let multiwalletAvailable = FirmwareVersion(major: 4, minor: 0)
    /// Field on card that describes is passcode is default value or not
    static let isPasscodeStatusAvailable = FirmwareVersion(major: 4, minor: 1)
    /// Read-write files
    static let filesAvailable = FirmwareVersion(major: 3, minor: 29)
    
    static let min = FirmwareVersion(major: 0, minor: 0)
    static let max = FirmwareVersion(major: Int.max, minor: 0)
}

@available(iOS 13.0, *)
public extension FirmwareVersion {
    enum FirmwareType: String, Codable, CaseIterable, JSONStringConvertible {
        case sdk = "d SDK"
        case release = "r"
        case special
        
        static func type(for str: String) -> FirmwareType {
            FirmwareType(rawValue: str) ?? .special
        }
    }
}
