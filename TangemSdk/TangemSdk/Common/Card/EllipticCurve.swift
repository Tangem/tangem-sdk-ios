//
//  EllipticCurve.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Elliptic curve used for wallet key operations.
@available(iOS 13.0, *)
public enum EllipticCurve: String, Codable, CaseIterable {
	case secp256k1
	case ed25519
    case secp256r1
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.singleValueContainer()
		let stringValue = try values.decode(String.self).lowercased()
		if let curve = EllipticCurve(rawValue: stringValue) {
			self = curve
		} else {
			throw TangemSdkError.decodingFailed("Failed to decode elliptic curve value")
		}
	}
}
