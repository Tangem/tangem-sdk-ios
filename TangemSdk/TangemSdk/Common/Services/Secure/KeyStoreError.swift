//
//  SecureStorageService.swift
//Errors that can be generated as a result of attempting to store keys.
//  TangemSdk
//
//  Created by Alexander Osokin on 25.06.2021.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// An error we can throw when something goes wrong.
struct KeyStoreError: Error, CustomStringConvertible {
    var message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var description: String {
        return message
    }
}

@available(iOS 13.0, *)
extension OSStatus {
    
    /// A human readable message for the status.
    var message: String {
        return (SecCopyErrorMessageString(self, nil) as String?) ?? String(self)
    }
}
