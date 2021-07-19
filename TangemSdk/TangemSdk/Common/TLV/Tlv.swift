//
//  Tlv.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// The data converted to the Tag Length Value protocol.
@available(iOS 13.0, *)
public struct Tlv: Equatable {
    public let tag: TlvTag
    public let tagRaw: Byte
    public let value: Data
    
    public init (_ tag: TlvTag, value: Data) {
        self.tag = tag
        self.tagRaw = tag.rawValue
        self.value = value
    }
    
    public init (tagRaw: Byte, value: Data) {
        self.tag = TlvTag(rawValue: tagRaw) ?? .unknown
        self.tagRaw = tagRaw
        self.value = value
    }
    
    /// Serialize TLV to Data
    public func serialize() -> Data {
        var bytes = Data()
        let length = value.count
        bytes.reserveCapacity(1 + length)
        bytes.append(tagRaw)
        
        //serialize length
        if length > 0xFE { //long format
            bytes.append(0xFF)
            bytes.append(contentsOf: length.bytes2)
        } else if length > 0 { //short format
            let lengthAsByte = length.byte
            bytes.append(lengthAsByte)
        } else {
            bytes.append(0x00)
        }
        
        //serialize data
        bytes.append(contentsOf: value)
        return bytes
    }
    
    /// Try to deserialize raw data to array of tlv items
    /// - Parameter data: raw TLV-array
    public static func deserialize(_ data: Data) -> [Tlv]? {
        let dataStream = InputStream(data: data)
        dataStream.open()
        defer { dataStream.close() }
        
        var tags = [Tlv]()
        while dataStream.hasBytesAvailable {
            guard let tagCode = dataStream.readByte(),
                let dataLength = readTagLength(dataStream),
                let data = dataLength > 0 ? dataStream.readBytes(count: dataLength) : Data()  else {
                Log.warning("Failed to read tag from stream")
                    return tags.count > 0 ? tags : nil
            }
            
            let tlvItem = Tlv(tagRaw: tagCode, value: data)
            tags.append(tlvItem)
        }
        
        return tags
    }
    
    /// Helper method. Try to read length from dataStream
    /// - Parameter dataStream: dataStream initialized with raw tlv
    private static func readTagLength(_ dataStream: InputStream) -> Int? {
        guard let shortLengthBytes = dataStream.readByte() else {
            Log.error("Failed to read tag lenght")
            return nil
        }
        
        if (shortLengthBytes == 0xFF) {
            guard let longLengthBytes = dataStream.readBytes(count: 2) else {
                Log.error("Failed to read tag long lenght")
                return nil
            }
            
            return Int(hexData: longLengthBytes)
        } else {
            return Int(hexData: Data([shortLengthBytes]))
        }
    }
}

@available(iOS 13.0, *)
extension Tlv: CustomStringConvertible {
    public var description: String {
        let tagName = "\(tag)".capitalizingFirst()
        let tagFullName = "TAG_\(tagName)"
        let size = String(format: "%02d",  value.count)
        return "\(tagFullName) [0x\(tagRaw):\(size)]: \(value)"
    }
}
