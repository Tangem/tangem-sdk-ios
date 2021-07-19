//
//  TlvTag.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Contains all possible value types that value for `TlvTag` can contain.
public enum TlvValueType: String {
    case hexString
    case utf8String
    case intValue
    case boolValue
    case data
    case ellipticCurve
    case dateTime
    case productMask
    case settingsMask
    case status
    case signingMethod
    case byte
    case uint16
    case interactionMode
	case fileSettings
}
/// Contains all TLV tags, with their code and descriptive name.
public enum TlvTag: Byte {
    case unknown = 0x00
    case cardId = 0x01
    case pin = 0x10
    case pin2 = 0x11
    case transactionOutHash = 0x50
    case transactionOutHashSize = 0x51
    case walletSignature = 0x61
    case walletRemainingSignatures = 0x62
    case walletSignedHashes = 0x63
    case pause = 0x1C
    case flash = 0x28
    case issuerTxSignature = 0x34
    case status = 0x02
    case cardPublicKey = 0x03
    case cardSignature = 0x04
    case curveId = 0x05
    case hashAlgId = 0x06
    case signingMethod = 0x07
    case maxSignatures = 0x08
    case pauseBeforePin2 = 0x09
    case settingsMask = 0x0A
    case cardData = 0x0C
    case ndefData = 0x0D
    case createWalletAtPersonalize = 0x0E
    case health = 0x0F
    case newPin = 0x12
    case newPin2 = 0x13
    case newPin3 = 0x1E
    case crExKey = 0x1F
    case publicKeyChallenge = 0x14
    case publicKeySalt = 0x15
    case challenge = 0x16
    case salt = 0x17
    case validationCounter = 0x18
    case cvc = 0x19
    case sessionKeyA = 0x1A
    case sessionKeyB = 0x1B
    case uid = 0x0B
    case manufacturerName = 0x20
    case manufacturerSignature = 0x21
    case issuerPublicKey = 0x30
    case issuerTransactionPublicKey = 0x31
    case issuerData = 0x32
    case issuerDataSignature = 0x33
    case issuerDataCounter = 0x35
    case isActivated = 0x3A
    case activationSeed = 0x3B
    case paymentFlowVersion = 0x54
    case userData = 0x2A
    case userProtectedData = 0x2B
    case userCounter = 0x2C
    case userProtectedCounter = 0x2D
    case resetPin = 0x36
    case codePageAddress = 0x40
    case codePageCount = 0x41
    case codeHash = 0x42
    case trOutRaw = 0x52
    case walletPublicKey = 0x60
    case firmwareVersion = 0x80
    case batchId = 0x81
    case manufactureDateTime = 0x82
    case issuerName = 0x83
    case blockchainName = 0x84
    case manufacturerPublicKey = 0x85
    case cardIDManufacturerSignature = 0x86
    case tokenSymbol = 0xA0
    case tokenContractAddress = 0xA1
    case tokenDecimal = 0xA2
    case tokenName = 0xA3
    case denomination = 0xC0
    case validatedBalance = 0xC1
    case lastSignDate = 0xC2
    case denominationText = 0xC3
    case checkWalletCounter = 0x64
    case productMask = 0x8A
    case isLinked = 0x58
    case terminalPublicKey = 0x5C
    case terminalTransactionSignature = 0x57
    case legacyMode = 0x29
    case interactionMode = 0x23
    case offset = 0x24
    case size = 0x25
    case acquirerPublicKey = 0x37
    
    case fullname = 0xD0
    case birthday = 0xD1
    case photo = 0xD2
    case gender = 0xD3
    case issueDate = 0xD4
    case expireDate = 0xD5
    case trustedAddress = 0xD6
	
	case pin2IsDefault = 0x59
	
	// MARK: - Multi-wallet
	case walletIndex = 0x65
	case walletsCount = 0x66
	case walletData = 0x67
	case cardWallet = 0x68
	
	// MARK: - Tlv tags for files
	case fileIndex = 0x26
	case fileSettings = 0x27
	
	case fileTypeName = 0x70
	case fileData = 0x71
	case fileOwnerIndex = 0x75
	
	// MARK: - Ttl value types
    /// `TlvValueType` associated with a `TlvTag`
    var valueType: TlvValueType {
        switch self {
        case .cardId, .batchId, .crExKey:
            return .hexString
        case .manufacturerName, .firmwareVersion, .issuerName, .blockchainName, .tokenSymbol, .tokenName, .tokenContractAddress,
			 .fullname, .birthday, .gender, .issueDate, .expireDate, .trustedAddress, .fileTypeName:
            return .utf8String
        case .curveId:
            return .ellipticCurve
        case .maxSignatures, .walletRemainingSignatures, .walletSignedHashes, .userProtectedCounter,
             .userCounter, .tokenDecimal, .issuerDataCounter, .checkWalletCounter:
            return .intValue
        case .isActivated, .isLinked, .createWalletAtPersonalize, .pin2IsDefault:
            return .boolValue
        case .manufactureDateTime:
            return .dateTime
        case .productMask:
            return .productMask
        case .settingsMask:
            return .settingsMask
        case .status:
            return .status
        case .signingMethod:
            return .signingMethod
		case .transactionOutHashSize, .legacyMode, .fileIndex, .health, .walletIndex, .walletsCount, .fileOwnerIndex:
            return .byte
        case .interactionMode:
            return .interactionMode
		case .offset, .size, .pauseBeforePin2:
            return .uint16
		case .fileSettings:
			return .fileSettings
        default:
            return .data
        }
    }
}
