//
//  Array+Tlv.swift
//  TangemSdk
//
//  Created by Andrew Son on 22/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension Array where Element == Tlv {
    /// Serialize array of tlv items to Data
    /// - Parameter array: tlv array
    public func serialize() -> Data {
        return Data(self.reduce([], { $0 + $1.serialize() }))
    }
    
    /// Convinience getter for tlv item
    /// - Parameter tag: tag to find
    public func item(for tag: TlvTag) -> Element? {
        first(where: { $0.tag == tag })
    }
    
    /// Convinience getter for tlv
    /// - Parameter tag: tag to find
    public func value(for tag: TlvTag) -> Data? {
        item(for: tag)?.value
    }
    
    /// - Parameter tag: tag to check
    public func contains(tag: TlvTag) -> Bool {
        value(for: tag) != nil
    }
    
    /// Convinience getter for multiple tlvs with same tag
    /// - Parameter tag: tag to find
    public func items(for tag: TlvTag) -> [Element] {
        filter { $0.tag == tag }
    }
}
