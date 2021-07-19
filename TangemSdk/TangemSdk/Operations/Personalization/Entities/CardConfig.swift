//
//  CardConfig.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
/**
 * It is a configuration file with all the card settings that are written on the card
 * during [PersonalizeCommand].
 */
@available(iOS 13.0, *)
public struct CardConfig: Decodable {
    let releaseVersion: Bool
    let issuerName: String
    let series: String?
    let startNumber: Int64
    let count: Int
    let numberFormat: String
    let pin: Data
    let pin2: Data
    let pin3: Data?
    let hexCrExKey: String?
    let cvc: String
    let pauseBeforePin2: Int
    let smartSecurityDelay: Bool
    let curveID: EllipticCurve
    let signingMethod: SigningMethod
    let maxSignatures: Int?
    let allowSetPIN1: Bool
    let allowSetPIN2: Bool
    let useActivation: Bool
    let useCvc: Bool
    let useNDEF: Bool
    let useDynamicNDEF: Bool?
    let useOneCommandAtTime: Bool?
    let useBlock: Bool
    let allowSelectBlockchain: Bool
    let prohibitPurgeWallet: Bool
    let allowUnencrypted: Bool
    let allowFastEncryption: Bool
    let protectIssuerDataAgainstReplay: Bool?
    let prohibitDefaultPIN1: Bool
    let disablePrecomputedNDEF: Bool?
    let skipSecurityDelayIfValidatedByIssuer: Bool
    let skipCheckPIN2CVCIfValidatedByIssuer: Bool
    let skipSecurityDelayIfValidatedByLinkedTerminal: Bool
    let restrictOverwriteIssuerExtraData: Bool?
    let disableIssuerData: Bool?
    let disableUserData: Bool?
    let disableFiles: Bool?
    let createWallet: Int
    let cardData: CardConfigData
    let ndefRecords: [NdefRecord]
    /// Number of wallets supported by card, by default - 1
    let walletsCount: Byte?
    
    private static let Alf = "ABCDEF0123456789"
    
    enum CodingKeys: String, CodingKey {
        case releaseVersion, issuerName, series, startNumber, count, numberFormat,
             hexCrExKey, smartSecurityDelay, curveID, maxSignatures,
             useActivation, useBlock, allowSelectBlockchain, skipSecurityDelayIfValidatedByIssuer, skipSecurityDelayIfValidatedByLinkedTerminal, disableIssuerData,
             disableUserData, disableFiles, createWallet, cardData, walletsCount,
             useDynamicNDEF, useOneCommandAtTime, protectIssuerDataAgainstReplay,
             disablePrecomputedNDEF, restrictOverwriteIssuerExtraData
        case pin = "PIN"
        case pin2 = "PIN2"
        case pin3 = "PIN3"
        case cvc = "CVC"
        case pauseBeforePin2 = "pauseBeforePIN2"
        case signingMethod = "SigningMethod"
        case allowSetPIN1 = "allowSwapPIN"
        case allowSetPIN2 = "allowSwapPIN2"
        case useCvc = "useCVC"
        case useNDEF = "useNDEF"
        case prohibitPurgeWallet = "forbidPurgeWallet"
        case allowUnencrypted = "protocolAllowUnencrypted"
        case allowFastEncryption = "protocolAllowStaticEncryption"
        case prohibitDefaultPIN1 = "forbidDefaultPIN"
        case skipCheckPIN2CVCIfValidatedByIssuer = "skipCheckPIN2andCVCIfValidatedByIssuer"
        case ndefRecords = "NDEF"
    }
    
    func createSettingsMask() -> CardSettingsMask {
        let builder = MaskBuilder<CardSettingsMask>()
        
        if allowSetPIN1 {
            builder.add(.allowSetPIN1)
        }
        if allowSetPIN2 {
            builder.add(.allowSetPIN2)
        }
        if useCvc {
            builder.add(.useCvc)
        }
        
        //Now we can personalize only reusable wallets
        builder.add(.isReusable)
        
        if useOneCommandAtTime ?? false {
            builder.add(.useOneCommandAtTime)
        }
        if useNDEF {
            builder.add(.useNDEF)
        }
        if useDynamicNDEF ?? false {
            builder.add(.useDynamicNDEF)
        }
        if disablePrecomputedNDEF ?? false {
            builder.add(.disablePrecomputedNDEF)
        }
        if allowUnencrypted {
            builder.add(.allowUnencrypted)
        }
        if allowFastEncryption {
            builder.add(.allowFastEncryption)
        }
        if prohibitDefaultPIN1 {
            builder.add(.prohibitDefaultPIN1)
        }
        if useActivation {
            builder.add(.useActivation)
        }
        if useBlock {
            builder.add(.useBlock)
        }
        if smartSecurityDelay {
            builder.add(.smartSecurityDelay)
        }
        if protectIssuerDataAgainstReplay ?? false {
            builder.add(.protectIssuerDataAgainstReplay)
        }
        if prohibitPurgeWallet {
            builder.add(.permanentWallet)
        }
        if allowSelectBlockchain {
            builder.add(.allowSelectBlockchain)
        }
        if skipCheckPIN2CVCIfValidatedByIssuer {
            builder.add(.skipCheckPIN2CVCIfValidatedByIssuer)
        }
        if skipSecurityDelayIfValidatedByIssuer {
            builder.add(.skipSecurityDelayIfValidatedByIssuer)
        }
        if skipSecurityDelayIfValidatedByLinkedTerminal {
            builder.add(.skipSecurityDelayIfValidatedByLinkedTerminal)
        }
        if restrictOverwriteIssuerExtraData ?? false {
            builder.add(.restrictOverwriteIssuerExtraData)
        }
        if disableIssuerData ?? false {
            builder.add(.disableIssuerData)
        }
        if disableUserData ?? false  {
            builder.add(.disableUserData)
        }
        if disableFiles ?? false {
            builder.add(.disableFiles)
        }
        return builder.build()
    }
    
    func createCardId() -> String? {
        guard let series = self.series else {
            return nil
        }
        
        if startNumber <= 0 || (series.count != 2 && series.count != 4) {
            return nil
        }
        
        if !checkSeries(series) {
            return nil
        }
        
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = series.count == 2 ? 13 : 11
        guard let tail = formatter.string(from: NSNumber(value: startNumber)) else {
            return nil
        }
        
        var cardId = (series + tail).replacingOccurrences(of: " ", with: "")
        
        guard let firstCidCharacter = cardId.first, let secondCidCharacter = cardId.dropFirst().first else {
            return nil
        }
        
        if cardId.count != 15 || !CardConfig.Alf.contains(firstCidCharacter) || !CardConfig.Alf.contains(secondCidCharacter) {
            return nil
        }
        
        cardId += "0"
        var sum: UInt32 = 0
        for i in 0..<cardId.count {
            // get digits in reverse order
            let index = cardId.index(cardId.endIndex, offsetBy: -i-1)
            let cDigit = cardId[index]
            let cDigitInt = cDigit.unicodeScalars.first!.value
            var digit = ("0"..."9").contains(cDigit) ?
                cDigitInt - UnicodeScalar("0").value
                : cDigitInt - UnicodeScalar("A").value
            
            // every 2nd number multiply with 2
            if i % 2 == 1 {
                digit *= 2
            }
            
            sum += digit > 9 ? digit - 9 : digit
        }
        let lunh = (10 - sum % 10) % 10
        return cardId[..<cardId.index(cardId.startIndex, offsetBy: 15)] + String(format: "%d", lunh)
    }
    
    private func checkSeries(_ series: String) -> Bool {
        let containsList = series.filter { CardConfig.Alf.contains($0) }
        return containsList.count == series.count
    }
}

@available(iOS 13.0, *)
extension CardConfig {
    struct CardConfigData: Decodable {
        let date: Date?
        let batch: String
        let blockchain: String
        let productNote: Bool?
        let productTag: Bool?
        let productIdCard: Bool?
        let productIdIssuer: Bool?
        let productAuthentication: Bool?
        let productTwin: Bool?
        let tokenSymbol: String?
        let tokenContractAddress: String?
        let tokenDecimal: Int?
        
        func createPersonalizationCardData(issuer: Issuer, manufacturer: Manufacturer, cardId: String) throws -> CardData {
            guard let manufacturerSignature = Secp256k1Utils.sign(Data(hexString: cardId), with: manufacturer.keyPair.privateKey) else {
                throw TangemSdkError.serializeCommandError
            }
            
            return CardData(batchId: batch,
                            manufactureDateTime: date ?? Date(),
                            issuerName: issuer.name,
                            blockchainName: blockchain,
                            manufacturerSignature: manufacturerSignature,
                            productMask: createProductMask(),
                            tokenSymbol: tokenSymbol,
                            tokenContractAddress: tokenContractAddress,
                            tokenDecimal: tokenDecimal)
        }
        
        func createProductMask() -> ProductMask {
            let builder = MaskBuilder<ProductMask>()
            
            if productNote ?? false {
                builder.add(.note)
            }
            
            if productTag ?? false {
                builder.add(.tag)
            }
            
            if productIdCard ?? false {
                builder.add(.idCard)
            }
            
            if productIdIssuer ?? false {
                builder.add(.idIssuer)
            }
            
            if productTwin ?? false {
                builder.add(.twinCard)
            }
            
            if productAuthentication ?? false {
                builder.add(.authentication)
            }
            
            return builder.build()
        }
    }
}

class MaskBuilder<T: OptionSet> where T.RawValue: FixedWidthInteger {
    private var rawValue: T.RawValue = 0
    
    func add(_ mask: T) {
        rawValue |= mask.rawValue
    }
    
    func build() -> T {
        return .init(rawValue: rawValue)
    }
}
