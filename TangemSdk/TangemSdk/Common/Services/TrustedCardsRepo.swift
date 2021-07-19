//
//  TrustedCardsRepo.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class TrustedCardsRepo {
    private let storage = SecureStorage()
    private let secureEnclave = SecureEnclaveService()
    
    //Key is Hash of card's public key
    private var data: [Data: Attestation] = [:]
    
    init() {
        try? fetch()
    }
    
    func append(cardPublicKey: Data, attestation: Attestation) {
        let maxIndex = data.map({ $0.value.index }).max() ?? 0
        var newAttestation = attestation
        newAttestation.index = maxIndex + 1
        
        if newAttestation.index >= Constants.maxCards,
           let keyWithMinIndex = data.min(by: { $0.value.index < $1.value.index })?.key {
            data[keyWithMinIndex] = nil
        }
        
        let hash = cardPublicKey.getSha256()
        data[hash] = attestation
        try? save()
    }
    
    func attestation(for cardPublicKey: Data) -> Attestation? {
        let hash = cardPublicKey.getSha256()
        return data[hash]
    }
    
    private func save() throws {
        let convertedData = data.mapValues { $0.rawRepresentation }
        let encoded = try JSONEncoder.tangemSdkEncoder.encode(convertedData)
        let signature = try secureEnclave.sign(data: encoded)
        try storage.store(object: encoded, account: StorageKey.attestedCards.rawValue)
        try storage.store(object: signature, account: StorageKey.signatureOfAttestedCards.rawValue)
    }
    
    private func fetch() throws {
        if let data = try storage.get(account: StorageKey.attestedCards.rawValue),
           let signature = try storage.get(account: StorageKey.signatureOfAttestedCards.rawValue),
           try secureEnclave.verify(signature: signature, message: data) {
            let decoded = try JSONDecoder.tangemSdkDecoder.decode([Data: String].self, from: data)
            let converted = decoded.compactMapValues { Attestation(rawRepresentaion: $0) }
            self.data = converted
        }
    }
}

@available(iOS 13.0, *)
private extension TrustedCardsRepo {
    /// Keys used for store data in Keychain
    enum StorageKey: String {
        case attestedCards
        case signatureOfAttestedCards
    }
}

@available(iOS 13.0, *)
private extension TrustedCardsRepo {
    enum Constants {
        static var maxCards = 1000 //todo: Think about it!
    }
}
