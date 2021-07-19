//
//  PinCode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

///// Contains information about the user code
@available(iOS 13.0, *)
struct UserCode {
    let type: UserCodeType
    let value: Data?
    
    init(_ type: UserCodeType) {
        self.value = type.defaultValue.sha256()
        self.type = type
    }
    
    init(_ type: UserCodeType, stringValue: String) {
        self.value = stringValue.sha256()
        self.type = type
    }
    
    init(_ type: UserCodeType, value: Data?) {
        self.value = value
        self.type = type
    }
}

public enum UserCodeType {
    case accessCode
    case passcode
    
    var defaultValue: String {
        switch self {
        case .accessCode:
            return UserCodeType.defaultAccessCode
        case .passcode:
            return UserCodeType.defaultPasscode
        }
    }
}

//MARK: Constants
private extension UserCodeType {
    static let defaultAccessCode = "000000"
    static let defaultPasscode = "000"
}
