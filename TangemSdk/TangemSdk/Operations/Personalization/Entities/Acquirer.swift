//
//  Acquirer.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Acquirer: Codable, JSONStringConvertible {
    let keyPair: KeyPair
    let name: String?
    let id: String?
}
