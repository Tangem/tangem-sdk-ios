//
//  Instruction.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Instruction code that determines the type of the command that is sent to the Tangem card.
/// It is used in the construction of `CommandApdu`.
public enum Instruction: Byte {
	case unknown = 0x00
	case read = 0xF2
	case attestCardKey = 0xF3
	case attestCardUniqueness = 0xF4
	case attestCardFirmware = 0xF5
	case writeIssuerData = 0xF6
	case readIssuerData = 0xF7
	case createWallet = 0xF8
	case attestWalletKey = 0xF9
	case setPin = 0xFA
	case sign = 0xFB
	case purgeWallet = 0xFC
	case activate = 0xFE
	case openSession = 0xFF
	case writeUserData = 0xE0
	case readUserData = 0xE1
	case personalize = 0xF1
	case depersonalize = 0xE3
	case readFileData = 0xD1
	case writeFileData = 0xD0
}

