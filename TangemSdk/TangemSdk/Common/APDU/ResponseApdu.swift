//
//  ResponseApdu.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/// Stores response data from the card and parses it to `Tlv` and `StatusWord`.
@available(iOS 13.0, *)
public struct ResponseApdu {
    /// Status word code, reflecting the status of the response
    public var sw: UInt16 { return UInt16( (UInt16(sw1) << 8) | UInt16(sw2) ) }
    /// Parsed status word.
    public var statusWord: StatusWord { return StatusWord(rawValue: sw) ?? .unknown }
    
    private let sw1: Byte
    private let sw2: Byte
    private let data: Data
    
    public init(_ data: Data, _ sw1: Byte, _ sw2: Byte) {
        self.sw1 = sw1
        self.sw2 = sw2
        self.data = data
    }
    
    /// Converts raw response data  to the array of TLVs.
    /// - Parameter encryptionKey: key to decrypt response.
    public func getTlvData(encryptionKey: Data? = nil) -> [Tlv]? {
        guard let tlv = Tlv.deserialize(data) else { // Initialize TLV array with raw data from card response
            return nil
        }
        
        return tlv
    }
    
    func decrypt(encryptionKey: Data?) throws -> ResponseApdu {
        guard let key = encryptionKey else {
            return self
        }
        
        if data.count == 0 { //error response. nothing to decrypt
            return self
        }
        
        if data.count < 16 { //not encrypted response. nothing to decrypt
            return self
        }
        
        let decryptedData = try data.decrypt(with: key)
        guard decryptedData.count >= 4 else {
            throw TangemSdkError.invalidResponseApdu
        }
        
        let length = decryptedData[0...1].toInt()
        let crc = decryptedData[2...3]
        let payload = decryptedData[4...]
        
        guard length == payload.count, crc == payload.crc16() else {
            throw TangemSdkError.invalidResponseApdu
        }
        
        return ResponseApdu(payload, self.sw1, self.sw2)
    }
}

@available(iOS 13.0, *)
extension ResponseApdu: CustomStringConvertible {
    public var description: String {
        return "<-- RECEIVED [\(data.count + 2) bytes]: \(data) \(sw1) \(sw2) (SW: \(statusWord))"
    }
}
