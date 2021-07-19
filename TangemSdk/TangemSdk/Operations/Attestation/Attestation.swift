//
//  VerificationState.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public struct Attestation: JSONStringConvertible, Equatable {
    /// Attestation status of card's public key
    public internal(set) var cardKeyAttestation: Status
    /// Attestation status of all wallet public key in the card
    public internal(set) var walletKeysAttestation: Status
    /// Attestation status of card's firmware. Not implemented for this time
    public internal(set) var firmwareAttestation: Status
    /// Attestation status of card's uniqueness. Not implemented for this time
    public internal(set) var cardUniquenessAttestation: Status
    
    /// Index for storage
    var index: Int = 0
    
    public var status: Status {
        if !statuses.contains(where: { $0 != .skipped } ) {
            return .skipped
        }
        
        if statuses.contains(.failed) {
            return .failed
        }
        
        if statuses.contains(.warning) {
            return .warning
        }
        
        if statuses.contains(.verifiedOffline) {
            return .verifiedOffline
        }
        
        return .verified
    }
    
    var mode: AttestationTask.Mode {
        if walletKeysAttestation == .skipped {
            return .normal
        }
        
        return .full
    }
    
    private var statuses: [Status] {
        return [cardKeyAttestation, walletKeysAttestation, firmwareAttestation, cardUniquenessAttestation]
    }
}

@available(iOS 13.0, *)
public extension Attestation {
    enum Status: String, Codable {
        case failed, warning, skipped, verifiedOffline, verified
    }
}

@available(iOS 13.0, *)
public extension Attestation {
    static var empty: Attestation {
        .init(cardKeyAttestation: .skipped,
              walletKeysAttestation: .skipped,
              firmwareAttestation: .skipped,
              cardUniquenessAttestation: .skipped)
    }
}

@available(iOS 13.0, *)
extension Attestation {
    var rawRepresentation: String {
        return "\(index),\(cardKeyAttestation.intRepresentation),\(walletKeysAttestation.intRepresentation),\(firmwareAttestation.intRepresentation),\(cardUniquenessAttestation.intRepresentation)"
    }
    
    init?(rawRepresentaion: String) {
        let values: [Int] = rawRepresentaion.split(separator: ",").compactMap { Int($0) }
        
        guard values.count == 5,
              let cardKeyAttestation = Status(intRepresentation: values[1]),
              let walletKeysAttestation = Status(intRepresentation: values[2]),
              let firmwareAttestation = Status(intRepresentation: values[3]),
              let cardUniquenessAttestation = Status(intRepresentation: values[4]) else {
            return nil
        }
        
        self.index = values[0]
        self.cardKeyAttestation = cardKeyAttestation
        self.walletKeysAttestation = walletKeysAttestation
        self.firmwareAttestation = firmwareAttestation
        self.cardUniquenessAttestation = cardUniquenessAttestation
    }
}

@available(iOS 13.0, *)
extension Attestation.Status {
    var intRepresentation: Int {
        switch self {
        case .failed: return 0
        case .warning: return 1
        case .skipped: return 2
        case .verifiedOffline: return 3
        case .verified: return 4
        }
    }
    
    public init?(intRepresentation: Int) {
        switch intRepresentation {
        case 0:
            self = .failed
        case 1:
            self = .warning
        case 2:
            self = .skipped
        case 3:
            self = .verifiedOffline
        case 4:
            self = .verified
        default:
            return nil
        }
    }
}

@available(iOS 13.0, *)
extension Attestation: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.index = (try? container.decode(Int.self, forKey: .index)) ?? 0
        self.cardKeyAttestation = try container.decode(Status.self, forKey: .cardKeyAttestation)
        self.walletKeysAttestation = try container.decode(Status.self, forKey: .walletKeysAttestation)
        self.firmwareAttestation = try container.decode(Status.self, forKey: .firmwareAttestation)
        self.cardUniquenessAttestation = try container.decode(Status.self, forKey: .cardUniquenessAttestation)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy:  CodingKeys.self)
        try container.encode(cardKeyAttestation, forKey: .cardKeyAttestation)
        try container.encode(walletKeysAttestation, forKey: .walletKeysAttestation)
        try container.encode(firmwareAttestation, forKey: .firmwareAttestation)
        try container.encode(cardUniquenessAttestation, forKey: .cardUniquenessAttestation)
    }

    enum CodingKeys: String, CodingKey {
        case index, cardKeyAttestation, walletKeysAttestation,
             firmwareAttestation, cardUniquenessAttestation
    }
}
