//
//  NdefRecord.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct NdefRecord: Codable {
    enum NdefRecordType: String, Codable {
        case uri
        case aar
        case text
    }
    
    let type: NdefRecordType
    let value: String
    
    func toBytes() -> Data? {
        return value.data(using: .utf8)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try values.decode(String.self, forKey: .type)
        if let type = NdefRecordType(rawValue: typeString.lowercased()) {
            self.type = type
        } else {
            throw TangemSdkError.decodingFailed("Failed to decode NdefRecordType")
        }
        value = try values.decode(String.self, forKey: .value)
    }
}
