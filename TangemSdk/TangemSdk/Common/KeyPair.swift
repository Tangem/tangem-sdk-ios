//
//  KeyPair.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Pair of private and public key
public struct KeyPair: Equatable, Codable {
    public let privateKey: Data
    public let publicKey: Data
}
