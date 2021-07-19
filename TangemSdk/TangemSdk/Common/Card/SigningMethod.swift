//
//  SigningMethod.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Determines which type of data is required for signing.
@available(iOS 13.0, *)
struct SigningMethod: OptionSet, OptionSetCustomStringConvertible {
    let rawValue: Byte
	
    init(rawValue: Byte) {
		if rawValue & 0x80 != 0 {
			self.rawValue = rawValue
		} else {
			self.rawValue = 0b10000000|(1 << rawValue)
		}
	}
}

//MARK: - Constants
@available(iOS 13.0, *)
extension SigningMethod {
    static let signHash = SigningMethod(rawValue: 0b10000000|(1 << 0))
    static let signRaw = SigningMethod(rawValue: 0b10000000|(1 << 1)) //todo: dv
    static let signHashSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 2))
    static let signRawSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 3)) //todo: dv
    static let signHashSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 4)) //todo: remove
    static let signRawSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 5)) //todo: remove
    static let signPos = SigningMethod(rawValue: 0b10000000|(1 << 6)) //todo: remove
}

//MARK: - OptionSetCodable conformance
@available(iOS 13.0, *)
extension SigningMethod: OptionSetCodable {
    enum OptionKeys: String, OptionKey {
        case signHash
        case signRaw
        case signHashSignedByIssuer
        case signRawSignedByIssuer
        case signHashSignedByIssuerAndUpdateIssuerData
        case signRawSignedByIssuerAndUpdateIssuerData
        case signPos
        
        var value: SigningMethod {
            switch self {
            case .signHash:
                return .signHash
            case .signRaw:
                return .signRaw
            case .signHashSignedByIssuer:
                return .signHashSignedByIssuer
            case .signRawSignedByIssuer:
                return .signRawSignedByIssuer
            case .signHashSignedByIssuerAndUpdateIssuerData:
                return .signHashSignedByIssuerAndUpdateIssuerData
            case .signRawSignedByIssuerAndUpdateIssuerData:
                return .signRawSignedByIssuerAndUpdateIssuerData
            case .signPos:
                return .signPos
            }
        }
    }
}
