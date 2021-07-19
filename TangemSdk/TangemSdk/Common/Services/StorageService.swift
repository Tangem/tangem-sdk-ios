//
//  StorageService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.


import Foundation

public class StorageService {
    static let prefix = "tng_"

    enum Keys: String {
        case hasSuccessfulTapIn
        case cardValues
    }

    func bool(forKey: StorageService.Keys) -> Bool {
        UserDefaults.standard.bool(forKey: rawKey(forKey, nil))
    }

    func set(boolValue: Bool, forKey: StorageService.Keys) {
        UserDefaults.standard.set(boolValue, forKey: rawKey(forKey, nil))
    }

    func string(forKey: StorageService.Keys) -> String? {
        UserDefaults.standard.string(forKey: rawKey(forKey, nil))
    }

    func set(stringValue: String, forKey: StorageService.Keys) {
        UserDefaults.standard.set(stringValue, forKey: rawKey(forKey, nil))
    }

    func object<T: Decodable>(forKey: StorageService.Keys, postfix: String? = nil) -> T? {
        if let data =  UserDefaults.standard.data(forKey: rawKey(forKey, postfix)) {
            let decoder = JSONDecoder()
            return try? decoder.decode(T.self, from: data)
        }
        return nil
    }

    func set<T: Encodable>(object: T, forKey: StorageService.Keys, postfix: String? = nil) {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(object)
        UserDefaults.standard.set(data, forKey: rawKey(forKey, postfix))
    }

    private func rawKey(_ forKey: StorageService.Keys, _ postfix: String?) -> String {
        let baseKey = "\(StorageService.prefix)\(forKey.rawValue)"
        if let postfix = postfix {
            return baseKey + "_\(postfix)"
        } else {
            return baseKey
        }
    }
}
