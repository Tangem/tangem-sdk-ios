//
//  NFCTag+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

@available(iOS 13.0, *)
extension NFCTag {
    var tagType: NFCTagType {
        switch self {
        case .iso7816(let iso7816Tag):
            return .tag(uid: iso7816Tag.identifier)
        default:
            return .unknown
        }
    }
}
