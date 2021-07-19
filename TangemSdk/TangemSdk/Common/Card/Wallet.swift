//
//  Wallet.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public extension Card {
    /// Describing wallets created on card
    struct Wallet: Codable {
        /// Wallet's public key.
        public let publicKey: Data
        /// Elliptic curve used for all wallet key operations.
        public let curve: EllipticCurve
        /// Wallet's settings
        public let settings: Settings
        /// Total number of signed hashes returned by the wallet since its creation
        /// COS 1.16+
        public var totalSignedHashes: Int?
        /// Remaining number of `Sign` operations before the wallet will stop signing any data.
        /// - Note: This counter were deprecated for cards with COS 4.0 and higher
        public var remainingSignatures: Int?
        /// Index of the wallet in the card storage
        public let index: Int
    }
}

@available(iOS 13.0, *)
public extension Card.Wallet {
    struct Settings: Codable {
        /// if true, erasing the wallet will be prohibited
        public let isPermanent: Bool
    }
}

@available(iOS 13.0, *)
extension Card.Wallet {
    /// Status of the wallet. 
    enum Status: Int, StatusType { //TODO: Specify
        /// Wallet not created
        case empty = 1
        /// Wallet created and can be used for signing
        case loaded = 2
        /// Wallet was purged and can't be recreated or used for signing
        case purged = 3
    }
}

@available(iOS 13.0, *)
extension Card.Wallet.Settings {
    /// Stores and maps Wallet settings
    /// - Note: Available only for cards with COS v.4.0
    struct Mask: OptionSet, OptionSetCustomStringConvertible {
        var rawValue: Int
        
        static let isPermanent = Mask(rawValue: 0x0004)
        static let isReusable = Mask(rawValue: 0x0001)
        
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

@available(iOS 13.0, *)
extension Card.Wallet.Settings {
    init(mask: WalletSettingsMask) {
        self.isPermanent = mask.contains(.isPermanent)
    }
}

@available(iOS 13.0, *)
typealias WalletSettingsMask = Card.Wallet.Settings.Mask

@available(iOS 13.0, *)
extension WalletSettingsMask: OptionSetCodable {
    enum OptionKeys: String, OptionKey {
        case isPermanent
        case isReusable
        
        var value: WalletSettingsMask {
            switch self {
            case .isPermanent:
                return .isPermanent
            case .isReusable:
                return .isReusable
            }
        }
    }
}
