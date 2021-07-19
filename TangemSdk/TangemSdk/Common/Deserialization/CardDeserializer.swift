//
//  CardSerializer.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct CardDeserializer {
    func deserialize(decoder: TlvDecoder, cardDataDecoder: TlvDecoder?) throws -> Card {
        let cardStatus: Card.Status = try decoder.decode(.status)
        try assertStatus(cardStatus)
        try assertActivation(try decoder.decode(.isActivated))
        
        guard let cardDataDecoder = cardDataDecoder  else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let firmware = FirmwareVersion(stringValue: try decoder.decode(.firmwareVersion))
        let cardSettingsMask: CardSettingsMask = try decoder.decode(.settingsMask)
        
        let isPasscodeSet: Bool? = firmware >= .isPasscodeStatusAvailable ?
            !(try decoder.decode(.pin2IsDefault)) : nil
        
        let defaultCurve: EllipticCurve = try decoder.decode(.curveId)
        let supportedCurves: [EllipticCurve] = firmware < .multiwalletAvailable ? [defaultCurve] : EllipticCurve.allCases
        let defaultSigningMethods: SigningMethod = try decoder.decode(.signingMethod)
        var wallets: [Card.Wallet] = []
        var remainingSignatures: Int? = nil
        
        if firmware < .multiwalletAvailable, cardStatus == .loaded {
            remainingSignatures = try decoder.decode(.walletRemainingSignatures)
            
            let walletSettings = Card.Wallet.Settings(mask: cardSettingsMask.toWalletSettingsMask())
            
            let wallet = Card.Wallet(publicKey: try decoder.decode(.walletPublicKey),
                                     curve: defaultCurve,
                                     settings: walletSettings,
                                     totalSignedHashes: try decoder.decode(.walletSignedHashes),
                                     remainingSignatures: remainingSignatures!,
                                     index: 0)
            
            wallets.append(wallet)
        }
        
        
        let manufacturer = Card.Manufacturer(name: try decoder.decode(.manufacturerName),
                                             manufactureDate: try cardDataDecoder.decode(.manufactureDateTime),
                                             signature: try cardDataDecoder.decode(.cardIDManufacturerSignature))
        
        let issuer = Card.Issuer(name: try cardDataDecoder.decode(.issuerName),
                                 publicKey: try decoder.decode(.issuerPublicKey))
        
        let securityDelay: Int? = try decoder.decode(.pauseBeforePin2)
        let securityDelayMs = securityDelay.map { $0 * 10 } ?? 0
        let settings = Card.Settings(securityDelay: securityDelayMs,
                                     maxWalletsCount: try decoder.decode(.walletsCount) ?? 1, //Cos before v4 always has 1 wallet
                                     mask: cardSettingsMask,
                                     defaultSigningMethods: defaultSigningMethods,
                                     defaultCurve: defaultCurve)
        
        let terminalIsLinked: Bool = try decoder.decode(.isLinked)
        
        let card = Card(cardId: try decoder.decode(.cardId),
                        batchId: try cardDataDecoder.decode(.batchId),
                        cardPublicKey: try decoder.decode(.cardPublicKey),
                        firmwareVersion: firmware,
                        manufacturer: manufacturer,
                        issuer: issuer,
                        settings: settings,
                        linkedTerminalStatus: terminalIsLinked ? .current : .none,
                        isPasscodeSet: isPasscodeSet,
                        supportedCurves: supportedCurves,
                        wallets: wallets,
                        health: try decoder.decode(.health),
                        remainingSignatures: remainingSignatures)
        
        
		return card
	}
    
    static func getDecoder(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> TlvDecoder {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        return TlvDecoder(tlv: tlv)
    }
    
    static func getCardDataDecoder(with environment: SessionEnvironment, from tlv: [Tlv]) throws -> TlvDecoder? {
        guard let cardDataValue = tlv.value(for: .cardData),
              let cardDataTlv = Tlv.deserialize(cardDataValue) else {
           return nil
        }
        
        return TlvDecoder(tlv: cardDataTlv)
    }
    
    private func assertActivation(_ isNeedActivation: Bool) throws {
        if isNeedActivation {
            throw TangemSdkError.notActivated
        }
    }
    
    private func assertStatus(_ status: Card.Status) throws {
        if status == .notPersonalized {
            throw TangemSdkError.notPersonalized
        }
        
        if status == .purged {
            throw TangemSdkError.walletIsPurged
        }
    }
}
