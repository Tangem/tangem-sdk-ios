//
//  CardFilter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public struct CardFilter {
    /// Filter that can be used to limit cards that can be interacted with in TangemSdk.
    public var allowedCardTypes: [FirmwareVersion.FirmwareType] = [.release]
    
    /// Use this filter to configure batches allowed to work with your app
    public var batchIdFilter: ItemFilter? = nil
    
    /// Use this filter to configure issuers allowed to work with your app
    public var issuerFilter: ItemFilter? = nil
    
    static var `default`: CardFilter = .init()
    
    public func isCardAllowed(_ card: Card) -> Bool {
        if !allowedCardTypes.contains(card.firmwareVersion.type) {
            return false
        }
        
        if let batchIdFilter = batchIdFilter,
           !batchIdFilter.isAllowed(card.batchId) {
            return false
        }
        
        if let issuerFilter = issuerFilter,
           !issuerFilter.isAllowed(card.issuer.name) {
            return false
        }
        
        return true
    }
}

@available(iOS 13.0, *)
public extension CardFilter {
    enum ItemFilter {
        case allow(_ items: Set<String>)
        case deny(_ items: Set<String>)
        
        func isAllowed(_ item: String) -> Bool {
            switch self {
            case .allow(let items):
                return items.contains(item)
            case .deny(let items):
                return !items.contains(item)
            }
        }
    }
}
