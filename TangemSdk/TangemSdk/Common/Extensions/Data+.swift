//
//  Data+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import CommonCrypto

@available(iOS 13.0, *)
extension Data {
    public var hexString: String {
        return self.map { return String(format: "%02X", $0) }.joined()
    }
    
    public var utf8String: String? {
        return String(bytes: self, encoding: .utf8)?.remove("\0")
    }
    
    public var description: String {
        return hexString
    }
    
    public func toInt() -> Int {
        return Int(hexData: self)
    }
    
    public func toDate() -> Date? {
        guard self.count >= 4 else { return nil }
        
        let year = Int(hexData: self[0...1])
        let month = Int(self[2])
        let day = Int(self[3])

        let components = DateComponents(year: year, month: month, day: day)
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)
    }
    
    public init(hexString: String) {
        self = Data()
        reserveCapacity(hexString.unicodeScalars.lazy.underestimatedCount)
        
        var buffer: UInt8?
        var skip = hexString.hasPrefix("0x") ? 2 : 0
        for char in hexString.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48 && char.value <= 102 else {
                removeAll()
                return
            }
            let v: UInt8
            let c: UInt8 = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                removeAll()
                return
            }
            if let b = buffer {
                append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        if let b = buffer {
            append(b)
        }
    }
    
    public func getSha256() -> Data {
        let digest = SHA256.hash(data: self)
        return Data(digest)
    }
    
    public func getSha512() -> Data {
        let digest = SHA512.hash(data: self)
        return Data(digest)
    }
    
    public var toBytes: [Byte] {
        return Array(self)
    }
    
    func decodeTlv<T>(tag: TlvTag) -> T? {
        guard let tlv = Tlv.deserialize(self) else{
            return nil
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return try? decoder.decode(tag)
    }
    
    public func pbkdf2(hash: CCPBKDFAlgorithm,
                salt: Data,
                keyByteCount: Int,
                rounds: Int) -> Data? {
        var derivedKeyData = Data(repeating: 0, count: keyByteCount)
        let derivedCount = derivedKeyData.count
        
        let derivationStatus: OSStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            let derivedKeyRawBytes = derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress
            return salt.withUnsafeBytes { saltBytes in
                let rawBytes = saltBytes.bindMemory(to: UInt8.self).baseAddress
                return self.withUnsafeBytes { pointer in
                    let typedPointer = pointer.bindMemory(to: Int8.self).baseAddress
                    return CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        typedPointer,
                        self.count,
                        rawBytes,
                        salt.count,
                        hash,
                        UInt32(rounds),
                        derivedKeyRawBytes,
                        derivedCount)
                }
            }
        }
        
        return derivationStatus == kCCSuccess ? derivedKeyData : nil
    }
    
    public func pbkdf2sha256(salt: Data, rounds: Int) -> Data? {
       return pbkdf2(hash: CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256), salt: salt, keyByteCount: 32, rounds: rounds)
    }
    
    //SO14443A
    public func crc16() -> Data {
        var wCRC = Int32(0x6363) // ITU-V.41
        forEach { byte in
            var chBlock = UInt8(byte)
            chBlock ^= UInt8(wCRC & 0x00FF)
            chBlock = chBlock ^ (chBlock << 4)
            let p1 = (wCRC >> 8) ^ (Int32(chBlock) & 0xFF) << 8 & 0xFFFF
            let p2 = ((Int32(chBlock) & 0xFF) << 3) & 0xFFFF
            let p3 = ((Int32(chBlock) & 0xFF) >> 4) & 0xFFFF
            wCRC = p1 ^ p2 ^ p3
        }
        return Data([UInt8(wCRC & 0xFF), UInt8((wCRC & 0xFFFF) >> 8)])
    }
    
    /// Encrypt data with  AES256-CBC and PKCS7
    /// - Parameter encryptionKey: key to encrypt
    /// - Throws: encription errors
    /// - Returns: Encripted data
    public func encrypt(with encryptionKey: Data) throws -> Data {
        return try CryptoUtils.crypt(operation: kCCEncrypt,
                                     algorithm: kCCAlgorithmAES,
                                     options: kCCOptionPKCS7Padding,
                                     key: encryptionKey,
                                     dataIn: self)
    }
    
    /// Decrypt data with  AES256-CBC and PKCS7
    /// - Parameter encryptionKey: key to decrypt
    /// - Throws: decryption errors
    /// - Returns: Decrypted data
    public func decrypt(with encryptionKey: Data) throws -> Data {
        return try CryptoUtils.crypt(operation: kCCDecrypt,
                                     algorithm: kCCAlgorithmAES,
                                     options: kCCOptionPKCS7Padding,
                                     key: encryptionKey,
                                     dataIn: self)
        
    }
	
	public func sign(privateKey: Data, curve: EllipticCurve = .secp256k1) -> Data? {
		switch curve {
		case .secp256k1:
			return Secp256k1Utils.sign(self, with: privateKey)
		default:
			// TODO: Create sign for ED25519 and secp256r1 curve
			fatalError("Sign not implemented for this curve")
		}
	}
}
