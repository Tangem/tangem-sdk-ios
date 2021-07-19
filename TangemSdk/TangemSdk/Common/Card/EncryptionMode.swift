//
//  EncryptionMode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// All available encryption modes
public enum EncryptionMode: String, Codable {
    case none
    case fast
    case strong
    
    var byteValue: Byte {
        switch self {
        case .none:
            return 0x00
        case .fast:
            return 0x01
        case .strong:
            return 0x02
        }
    }
}
