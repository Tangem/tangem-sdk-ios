//
//  Error+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.03.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public extension Error {
    func toTangemSdkError() -> TangemSdkError {
        return TangemSdkError.parse(self)
    }
}
