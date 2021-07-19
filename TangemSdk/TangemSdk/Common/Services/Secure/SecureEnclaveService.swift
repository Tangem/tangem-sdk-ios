//
//  SecureEnclaveService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOS 13.0, *)
struct SecureEnclaveService {
    private let storage = SecureStorage()
    
    func sign(data: Data) throws -> Data {
        let key = try makeOrRestoreKey()
        return try key.signature(for: data).rawRepresentation
    }
    
    func verify(signature: Data, message: Data) throws -> Bool {
        let key = try makeOrRestoreKey()
        let signature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
        return key.publicKey.isValidSignature(signature, for: message)
    }
    
    private func makeOrRestoreKey() throws -> SecureEnclave.P256.Signing.PrivateKey {
        if let restoredKey: SecureEnclave.P256.Signing.PrivateKey = try storage.readKey(account: StorageKey.secureEnclaveP256Key.rawValue) {
            return restoredKey
        }
        
        let key = try SecureEnclave.P256.Signing.PrivateKey()
        try storage.storeKey(key, account: StorageKey.secureEnclaveP256Key.rawValue)
        return key
    }
}

@available(iOS 13.0, *)
private extension SecureEnclaveService {
    /// Keys used for store data in Keychain
    enum StorageKey: String {
        case secureEnclaveP256Key
    }
}
