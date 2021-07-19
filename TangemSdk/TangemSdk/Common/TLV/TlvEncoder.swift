//
//  TlvEncoder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class TlvEncoder {
    public func encode<T>(_ tag: TlvTag, value: T?) throws -> Tlv {
        do {
            if let value = value {
                let tlv = try Tlv(tag, value: encode(value, for: tag))
                logTlv(tlv, value)
                return tlv
            } else {
                throw TangemSdkError.encodingFailed("Encoding error. Value for tag \(tag) is nil")
            }
        } catch {
            Log.error(error)
            throw error
        }
    }
    
    private func encode<T>(_ value: T, for tag: TlvTag) throws -> Data {
        switch tag.valueType {
        case .hexString:
            try typeCheck(value, String.self, for: tag)
            return Data(hexString: value as! String)
        case .utf8String:
            try typeCheck(value, String.self, for: tag)
            let string = value as! String + "\0"
            if let data = string.data(using: .utf8) {
                return data
            } else {
                throw TangemSdkError.encodingFailed("Encoding error. Failed to convert string to utf8 Data")
            }
        case .byte:
            do {
                try typeCheck(value, Int.self, for: tag)
                return (value as! Int).byte
            } catch {
                try typeCheck(value, Byte.self, for: tag)
                return Data([(value as! Byte)])
            }
        case .intValue:
            try typeCheck(value, Int.self, for: tag)
            return (value as! Int).bytes4
        case .uint16:
            try typeCheck(value, Int.self, for: tag)
            return (value as! Int).bytes2
        case .boolValue:
            try typeCheck(value, Bool.self, for: tag)
            let value = value as! Bool
            return value ? Data([Byte(1)]) : Data([Byte(0)])
        case .data:
            try typeCheck(value, Data.self, for: tag)
            return value as! Data
        case .ellipticCurve:
            try typeCheck(value, EllipticCurve.self, for: tag)
            let curve = value as! EllipticCurve
            if let data = (curve.rawValue + "\0").data(using: .utf8) {
                return data
            } else {
                throw TangemSdkError.encodingFailed("Encoding error. Failed to convert EllipticCurve to utf8 Data")
            }
        case .dateTime:
            try typeCheck(value, Date.self, for: tag)
            let date = value as! Date
            let calendar = Calendar(identifier: .gregorian)
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date)
            let d = calendar.component(.day, from: date)
            return y.bytes2 + m.byte + d.byte
        case .productMask:
            try typeCheck(value, ProductMask.self, for: tag)
            let mask = value as! ProductMask
            return Data([mask.rawValue])
        case .settingsMask:
			do {
                try typeCheck(value, CardSettingsMask.self, for: tag)
                let mask = value as! CardSettingsMask
				let rawValue = mask.rawValue
				if 0xFFFF0000 & rawValue != 0 {
					 return rawValue.bytes4
				} else {
					 return rawValue.bytes2
				}
			} catch {
                Log.warning("Settings mask type is not Card settings mask. Trying to check WalletSettingsMask")
			}
			
            try typeCheck(value, WalletSettingsMask.self, for: tag)
            let mask = value as! WalletSettingsMask
			return mask.rawValue.bytes4
        case .status:
            guard let statusType = value as? StatusType else {
                throw TangemSdkError.encodingFailedTypeMismatch("Encoding error for tag: \(tag)")
            }
            return statusType.rawValue.byte
        case .signingMethod:
            try typeCheck(value, SigningMethod.self, for: tag)
            let method = value as! SigningMethod
            return Data([method.rawValue])
        case .interactionMode:
            guard let mode = value as? InteractionMode else {
                throw TangemSdkError.encodingFailedTypeMismatch("Encoding error for tag: \(tag)")
            }
            return Data([mode.rawValue])
		case .fileSettings:
			try typeCheck(value, FileSettings.self, for: tag)
			let settings = value as! FileSettings
			return settings.rawValue.bytes2
        }
    }
    
    private func typeCheck<Value, ToType>(_ value: Value, _ to: ToType, for tag: TlvTag) throws {
        guard type(of: value) is ToType else {
            throw TangemSdkError.encodingFailedTypeMismatch("Encoding error for tag: \(tag). Value is \(value) of type \(Value.self). Expected: \(to).")
        }
    }
}

@available(iOS 13.0, *)
extension TlvEncoder: TlvLogging {}
