//
//  CommandApdu.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/// Class that provides conversion of serialized request and Instruction code
/// to a raw data that can be sent to the card.
@available(iOS 13.0, *)
public struct CommandApdu: Equatable {
    /// Instruction code that determines the type of request for the card.
    let ins: Byte
    
    //MARK: Header
    fileprivate let cla: Byte

    fileprivate let p1:  Byte
    fileprivate let p2:  Byte
    
    //MARK: Body
    /// An array of  serialized TLVs that are to be sent to the card
    fileprivate let data: Data
    fileprivate let le: Int
    
    /// Convinience initializer
    /// - Parameter instruction: Instruction code
    /// - Parameter tlv: data
    public init(_ instruction: Instruction, tlv: Data) {
        self.init(ins: instruction.rawValue, tlv: tlv)
    }
    
    /// Raw initializer
    /// - Parameter cla: Instruction class (CLA) byte
    /// - Parameter ins: Instruction code (INS) byte
    /// - Parameter p1:  P1 parameter byte
    /// - Parameter p2:  P2 parameter byte
    /// - Parameter le:  Le byte
    /// - Parameter tlv: data
    /// - Parameter encryptionKey: optional encryption - not implemented
    public init(cla: Byte = 0x00,
                ins: Byte,
                p1: Byte = 0x0,
                p2: Byte = 0x0,
                le: Int = -1,
                tlv: Data) {
        self.cla = cla
        self.ins = ins
        self.p1 = p1
        self.p2 = p2
        self.le = le
        data = tlv
    }
    
    /// Encrypt APDU
    /// - Parameters:
    /// - Parameter encryptionMode: encryption mode
    /// - Parameter encryptionKey: encryption key
    /// - Returns: Encrypted APDU
    public func encrypt(encryptionMode: EncryptionMode, encryptionKey: Data?) throws -> CommandApdu {
        guard let encryptionKey = encryptionKey, p1 == EncryptionMode.none.byteValue else { //skip if already encrypted or empty encryptionKey
            return self
        }
        let crc = data.crc16()
        let tlvDataToEncrypt = data.count.bytes2 + crc + data
        let encryptedPayload = try tlvDataToEncrypt.encrypt(with: encryptionKey)
        return CommandApdu(cla: self.cla, ins: self.ins, p1: encryptionMode.byteValue, p2: self.p2, le: self.le, tlv: Data(encryptedPayload))
    }
}

@available(iOS 13.0, *)
extension CommandApdu: CustomStringConvertible {
    public var description: String {
        let instruction = Instruction(rawValue: ins) ?? .unknown
        let lc = data.count.byte
        return "SEND --> \(instruction) [\(data.count + 4) bytes]: \(cla) \(ins) \(p1) \(p2) \(lc) \(data)"
    }
}

@available(iOS 13.0, *)
extension NFCISO7816APDU {
    convenience init(_ commandApdu: CommandApdu) {
        self.init(instructionClass: commandApdu.cla,
                  instructionCode: commandApdu.ins,
                  p1Parameter: commandApdu.p1,
                  p2Parameter: commandApdu.p2,
                  data: commandApdu.data,
                  expectedResponseLength: commandApdu.le)
    }
}
