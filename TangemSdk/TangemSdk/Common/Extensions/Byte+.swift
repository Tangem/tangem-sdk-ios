//
//  Byte+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public typealias Byte = UInt8

extension UInt8 {
    public var description: String {
        return hexString
    }
    
    public var hexString: String {
        return String(format: "%02X", self)
    }
}

extension UInt16 {
    public var description: String {
        return hexString
    }
    
    public var hexString: String {
        return String(format: "%02X", self)
    }
}
