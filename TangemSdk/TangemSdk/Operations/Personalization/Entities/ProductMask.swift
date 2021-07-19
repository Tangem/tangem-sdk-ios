//
//  ProductMask.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct ProductMask: OptionSet, OptionSetCustomStringConvertible {
    let rawValue: Byte
    
    init(rawValue: Byte) {
        self.rawValue = rawValue
    }
}

//MARK:- Constants
@available(iOS 13.0, *)
extension ProductMask {
    static let note = ProductMask(rawValue: 0x01)
    static let tag = ProductMask(rawValue: 0x02)
    static let idCard = ProductMask(rawValue: 0x04)
    static let idIssuer = ProductMask(rawValue: 0x08)
    static let authentication = ProductMask(rawValue: 0x10)
    static let twinCard = ProductMask(rawValue: 0x20)
}

//MARK: - OptionSetCodable conformance
@available(iOS 13.0, *)
extension ProductMask: OptionSetCodable {
    enum OptionKeys: String, OptionKey {
        case note
        case tag
        case idCard
        case idIssuer
        case twinCard
        
        var value: ProductMask {
            switch self {
            case .idCard:
                return .idCard
            case .idIssuer:
                return .idIssuer
            case .note:
                return .note
            case .tag:
                return .tag
            case .twinCard:
                return .twinCard
            }
        }
    }
}
