//
//  CardIdFormatter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.12.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Formatting CID in more readable manner
@available(iOS 13.0, *)
public struct CardIdFormatter {
    public init() {}
    
    public func crop(cid: String, with length: Int? = nil) -> String {
        length == nil ? cid : String(cid.dropLast().suffix(length!))
    }
    
    public func formatted(cid: String, numbers: Int? = nil) -> String {
        let croppedCid = crop(cid: cid, with: numbers)
        let format = "cid_format".localized
        return String(format: format, croppedCid)
    }
}
