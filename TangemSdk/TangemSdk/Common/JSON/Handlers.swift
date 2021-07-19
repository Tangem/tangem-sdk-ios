//
//  Handlers.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 21.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
class ScanHandler: JSONRPCHandler {
    var method: String { "SCAN" }
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = ScanTask()
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SignHashesHandler: JSONRPCHandler {
    var method: String { "SIGN_HASHES" }
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let hashes: [Data] = try parameters.value(for: "hashes")
        let command = SignHashesCommand(hashes: hashes,
                                  walletPublicKey: walletPublicKey)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SignHashHandler: JSONRPCHandler {
    var method: String { "SIGN_HASH" }
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let hash: Data = try parameters.value(for: "hash")
        
        let command = SignHashCommand(hash: hash,
                                  walletPublicKey: walletPublicKey)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class CreateWalletHandler: JSONRPCHandler {
    var method: String { "CREATE_WALLET" }
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let curve: EllipticCurve = try parameters.value(for: "curve")
        let isPermanent: Bool = try parameters.value(for: "isPermanent")
        let command = CreateWalletCommand(curve: curve, isPermanent: isPermanent)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class PurgeWalletHandler: JSONRPCHandler {
    var method: String { "PURGE_WALLET" }
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let command = PurgeWalletCommand(publicKey: walletPublicKey)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class PersonalizeHandler: JSONRPCHandler {
    var method: String { "PERSONALIZE" }
    
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let config: CardConfig = try parameters.value(for: "config")
        let issuer: Issuer = try parameters.value(for: "issuer")
        let manufacturer: Manufacturer = try parameters.value(for: "manufacturer")
        let acquirer: Acquirer = try parameters.value(for: "acquirer")
        
        let command = PersonalizeCommand(config: config,
                                         issuer: issuer,
                                         manufacturer: manufacturer,
                                         acquirer: acquirer)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class DepersonalizeHandler: JSONRPCHandler {
    var method: String { "DEPERSONALIZE" }
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = DepersonalizeCommand()
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SetAccessCodeHandler: JSONRPCHandler {
    var method: String { "SET_ACCESSCODE" }
    
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let accessCode: String? = try parameters.value(for: "accessCode")
        let command = SetUserCodeCommand(accessCode: accessCode)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SetPasscodeHandler: JSONRPCHandler {
    var method: String { "SET_PASSCODE" }
    
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let passcode: String? = try parameters.value(for: "passcode")
        let command = SetUserCodeCommand(passcode: passcode)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class ResetUserCodesHandler: JSONRPCHandler {
    var method: String { "RESET_USERCODES" }
    
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        return SetUserCodeCommand.resetUserCodes.eraseToAnyRunnable()
    }
}
//todo: reset array

/// Runs PreflightReadTask in `fullCardRead` mode
@available(iOS 13.0, *)
class PreflightReadHandler: JSONRPCHandler {
    var method: String { "PREFLIGHT_READ" }
    
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let cardId: String? = try parameters.value(for: "cardId")
        let mode: PreflightReadMode = try parameters.value(for: "readMode")
        let command = PreflightReadTask(readMode: mode, cardId: cardId)
        return command.eraseToAnyRunnable()
    }
}
