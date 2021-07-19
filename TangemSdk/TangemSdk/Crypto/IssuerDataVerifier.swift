//
//  IssuerDataVerifier.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 21.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
class IssuerDataVerifier {
    static func verify(cardId: String,
                       issuerData: Data,
                       issuerDataCounter: Int?,
                       publicKey: Data,
                       signature: Data) -> Bool {
        
        if let verifyResult = verify(cardId: cardId,
                                     issuerData: issuerData,
                                     issuerDataSize: nil,
                                     issuerDataCounter: issuerDataCounter,
                                     publicKey: publicKey,
                                     signature: signature),
            verifyResult == true { return true }
        return false
    }
    
    static func verify(cardId: String,
                       issuerDataSize: Int,
                       issuerDataCounter: Int?,
                       publicKey: Data,
                       signature: Data) -> Bool {
        
        if let verifyResult = verify(cardId: cardId,
                                     issuerData: nil,
                                     issuerDataSize: issuerDataSize,
                                     issuerDataCounter: issuerDataCounter,
                                     publicKey: publicKey,
                                     signature: signature),
            verifyResult == true { return true }
        return false
    }
    
    private static func verify(cardId: String,
                               issuerData: Data?,
                               issuerDataSize: Int?,
                               issuerDataCounter: Int?,
                               publicKey: Data,
                               signature: Data) -> Bool? {
        
        let encoder = TlvEncoder()
        var data = Data()
        do {
            data += try encoder.encode(.cardId, value: cardId).value
            if let issuerData = issuerData {
                data += try encoder.encode(.issuerData, value: issuerData).value
            }
            if let counter = issuerDataCounter {
                data += try encoder.encode(.issuerDataCounter, value: counter).value
            }
            if let size = issuerDataSize {
                data += try encoder.encode(.size, value: size).value
            }
        } catch { return nil }
        
        return CryptoUtils.verify(curve: .secp256k1,
                                  publicKey: publicKey,
                                  message: data,
                                  signature: signature)
    }
    
}
