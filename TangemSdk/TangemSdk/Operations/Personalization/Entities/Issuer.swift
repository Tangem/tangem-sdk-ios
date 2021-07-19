//
//  Issuer.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Issuer: Codable, JSONStringConvertible {
    let name: String
    let id: String
    let dataKeyPair: KeyPair
    let transactionKeyPair: KeyPair
}
