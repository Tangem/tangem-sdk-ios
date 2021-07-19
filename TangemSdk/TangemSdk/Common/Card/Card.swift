//
//  Card.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

///Response for `ReadCommand`. Contains detailed card information.
@available(iOS 13.0, *)
public struct Card: Codable, JSONStringConvertible {
	/// Unique Tangem card ID number.
	public let cardId: String
    /// Tangem internal manufacturing batch ID.
    public let batchId: String
	/// Public key that is used to authenticate the card against manufacturer’s database.
	/// It is generated one time during card manufacturing.
	public let cardPublicKey: Data
    /// Version of Tangem Card Operation System.
    public let firmwareVersion: FirmwareVersion
    /// Information about manufacturer
    public let manufacturer: Manufacturer
    /// Information about issuer
    public let issuer: Issuer
    /// Card setting, that were set during the personalization process
    public let settings: Settings
    /// When this value is `current`, it means that the application is linked to the card,
    /// and COS will not enforce security delay if `SignCommand` will be called
    /// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
    /// to be signed made with `TlvTag.TerminalPublicKey`.
    public let linkedTerminalStatus: LinkedTerminalStatus
    /// PIN2 (aka Passcode) is set.
    /// Available only for cards with COS v.4.0 and higher.
    public let isPasscodeSet: Bool?
    //TODO: isAccessCodeSet
    /// Array of ellipctic curves, supported by this card. Only wallets with these curves can be created.
    public let supportedCurves: [EllipticCurve]
    /// Wallets, created on the card, that can be used for signature
    internal(set) public var wallets: [Wallet] = []
    /// Card's attestation report
    internal(set) public var attestation: Attestation = .empty
    /// Any non-zero value indicates that the card experiences some hardware problems.
    /// User should withdraw the value to other blockchain wallet as soon as possible.
    /// Non-zero Health tag will also appear in responses of all other commands.
    @SkipEncoding
    var health: Int? //todo refactor
    /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
    /// - Note: This counter were deprecated for cards with COS 4.0 and higher
    @SkipEncoding
    var remainingSignatures: Int?
}

@available(iOS 13.0, *)
public extension Card {
    struct Manufacturer: Codable {
        /// Card manufacturer name.
        public let name: String
        /// Timestamp of manufacturing.
        public let manufactureDate: Date
        /// Signature of CardId with manufacturer’s private key. COS 1.21+
        public let signature: Data?
    }
    
    struct Issuer: Codable {
        /// Name of the issuer.
        public let name: String
        /// Public key that is used by the card issuer to sign IssuerData field.
        public let publicKey: Data
    }
    
    /// Card's linked terminal status. SDK can generate asymmetric key-pair and then use it for linking a card.
    enum LinkedTerminalStatus: String, Codable {
        // Current app instance is linked to the card
        case current
        // The other app/device is linked to the card
        case other
        // No app/device is linked
        case none
    }
}

@available(iOS 13.0, *)
extension Card {
    /// Status of the card and its wallet.
    enum Status: Int, StatusType { //TODO: Specify
        case notPersonalized = 0
        case empty = 1
        case loaded = 2
        case purged = 3
    }
}

