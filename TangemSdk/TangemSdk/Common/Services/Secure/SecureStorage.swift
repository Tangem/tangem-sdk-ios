//
//  SecureStorageService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Security

/// Helper class for Keychain
@available(iOS 13.0, *)
struct SecureStorage {
    func get(account: String) throws -> Data? {
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: account,
                     kSecMatchLimit: kSecMatchLimitOne,
                     kSecUseDataProtectionKeychain: true,
                     kSecReturnData: true] as [String: Any]
        
        
        var result: AnyObject?
        
        switch SecItemCopyMatching(query as CFDictionary, &result) {
        case errSecSuccess:
            guard let data = result as? Data else { return nil }
            
            return data
        case errSecItemNotFound:
            return nil
        case let status:
            throw KeyStoreError("Keychain read failed: \(status.message)")
        }
    }
    
    func store(object: Data, account: String, overwrite: Bool = true) throws  {
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: account,
                     kSecValueData: object,
                     kSecUseDataProtectionKeychain: true,
                     kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked] as [String : Any]
        
        var status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem && overwrite {
            let searchQuery = [kSecClass: kSecClassGenericPassword,
                               kSecAttrAccount: account] as [String: Any]
            
            let attributes = [kSecValueData: object] as [String: Any]
            
            status = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)
        }
        
        guard status == errSecSuccess else {
            throw KeyStoreError("Unable to store item: \(status.message)")
        }
    }
    
    /// Removes any existing data with the given account.
    func delete(account: String) throws {
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecUseDataProtectionKeychain: true,
                     kSecAttrAccount: account] as [String: Any]
        switch SecItemDelete(query as CFDictionary) {
        case errSecItemNotFound, errSecSuccess: break // Okay to ignore
        case let status:
            throw KeyStoreError("Unexpected deletion error: \(status.message)")
        }
    }
}

@available(iOS 13.0, *)
extension SecureStorage {
    /// Stores a CryptoKit key in the keychain as a generic password.
    func storeKey<T: GenericPasswordConvertible>(_ key: T, account: String) throws {
        try store(object: key.rawRepresentation, account: account, overwrite: true)
    }
    
    /// Reads a CryptoKit key from the keychain as a generic password.
    func readKey<T: GenericPasswordConvertible>(account: String) throws -> T? {
        if let data = try get(account: account) {
            return try T(rawRepresentation: data)
        }
        
        return nil
    }
}
