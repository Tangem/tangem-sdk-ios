//
//  NdefEncoder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


/**
 * Encodes information that is to be written on the card as an Ndef Tag.
 */
@available(iOS 13.0, *)
class NdefEncoder {
    private let ndefRecords: [NdefRecord]
    private let useDynamicNdef: Bool
    
    init(ndefRecords: [NdefRecord], useDynamicNdef: Bool) {
        self.ndefRecords = ndefRecords
        self.useDynamicNdef = useDynamicNdef
    }
    
    func encode() throws -> Data {
        let encodedData = try ndefRecords.enumerated().map { index, element -> Data in
            let headerValue = (index == 0 ? UInt8(0x80) : UInt8(0x00))
                | (!useDynamicNdef && index == ndefRecords.count - 1 ? 0x40 : 0x00)
            return try encodeValue(ndefRecord: element, headerValue: headerValue)
        }.joined()
        
        let sizeByte1 = (encodedData.count >> 8).byte
        let sizeByte2 = (encodedData.count & 0xFF).byte
        let result = sizeByte1 + sizeByte2 + encodedData
        return result
    }
    
    
    private func encodeValue(ndefRecord: NdefRecord, headerValue: UInt8) throws -> Data {
        guard let ndefRecordBytes = ndefRecord.toBytes() else {
            throw TangemSdkError.encodingFailed("Failed to encode NDEF")
        }
        
        var data = Data()
        switch ndefRecord.type {
        case .aar:
            data.append(headerValue|0x14) // NDEF Header
            data.append(0x0F) // Length of the record type
            data.append(ndefRecordBytes.count.byte) // Length of the payload data
            data.append(contentsOf: [0x61, 0x6E, 0x64, 0x72, 0x6F, 0x69, 0x64, 0x2E,
                                     0x63, 0x6F, 0x6D, 0x3A, 0x70, 0x6B, 0x67]) // type name
            data.append(ndefRecordBytes)
        case .uri:
            data.append(headerValue|0x11) // NDEF Header
            data.append(0x01) // Length of the record type
            var uriIdentifierCode: Byte
            var prefix: String
            
            if ndefRecord.value.starts(with: "http://www.") {
                uriIdentifierCode = 0x01
                prefix = "http://www."
            } else if ndefRecord.value.starts(with: "https://www.") {
                uriIdentifierCode = 0x02
                prefix = "https://www."
            } else if ndefRecord.value.starts(with: "http://") {
                uriIdentifierCode = 0x03
                prefix = "http://"
            } else if ndefRecord.value.starts(with: "https://") {
                uriIdentifierCode = 0x04
                prefix = "https://"
            } else {
                throw TangemSdkError.encodingFailed("Failed to parse uri scheme")
            }
            
            guard let value = ndefRecord.value.remove(prefix).data(using: .utf8) else {
                throw TangemSdkError.encodingFailed("Failed to remove scheme from NDEF record")
            }
            
            data.append((value.count + 1).byte) // Length of the payload data
            data.append(0x55) // URI
            data.append(uriIdentifierCode)
            data.append(value)
        case .text:
            data.append(headerValue|0x11) // NDEF Header
            data.append(0x01) // Length of the record type
            data.append((ndefRecordBytes.count + 1 + "en".count).byte) // Length of the payload data
            data.append(0x54) // Text
            data.append(0x02) // UTF8(MSB=0)|"en".length
            data.append("en".data(using: .utf8)!)
            data.append(ndefRecordBytes)
        }
        return data
    }
}
