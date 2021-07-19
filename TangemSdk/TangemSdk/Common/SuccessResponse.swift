//
//  SuccessResponse.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct SuccessResponse: JSONStringConvertible {
    public let cardId: String
    
    public init(cardId: String) {
        self.cardId = cardId
    }
}
