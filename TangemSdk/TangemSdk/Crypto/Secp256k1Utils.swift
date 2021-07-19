//
//  Secp256k1Utils.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk_secp256k1

@available(iOS 13.0, *)
public final class Secp256k1Utils {
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
    
    deinit {
        secp256k1_context_destroy(Secp256k1Utils.context)
    }
    
    public static func verify(publicKey: Data, message: Data, signature: Data) -> Bool? {
        guard let ctx = context else { return nil }
        
        let hashedMessage = message.getSha256()
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, signature.toBytes) == 1 else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, publicKey.toBytes, 65) == 1 else { return nil }
        
        let result = secp256k1_ecdsa_verify(ctx, &normalized, hashedMessage.toBytes, &pubkey) == 1
        return result
    }
    
    /**
     * Extension function to sign a byte array with the `Secp256k1` elliptic curve cryptography.
     *
     * - Parameter key: Key to sign data
     * - Parameter data: Data to sign
     *
     * - Returns: Signed data
     */
    public static func sign(_ data: Data, with key: Data) -> Data? {
        guard let ctx = context else { return nil }
        
        var signature = secp256k1_ecdsa_signature()
        let result = secp256k1_ecdsa_sign(ctx, &signature, Array(data.getSha256()), Array(key), nil, nil)
        guard result == 1 else {
            return nil
        }
        
        var signatureData = [Byte](repeating: 0, count: 64)
        _ = secp256k1_ecdsa_signature_serialize_compact(ctx, &signatureData, &signature)
        
        return Data(signatureData)
    }
    
    /// Generate private/public keypair with secp256k1.
    /// - Returns: `KeyPair` with  32-bytes length `private key` and  65-bytes length uncompressed `public key`
    public static func generateKeyPair() -> KeyPair? {
        guard let ctx = context else { return nil }
        
        guard let privateKey = (try? CryptoUtils.generateRandomBytes(count: 32))?.toBytes else { return nil }
        
        guard secp256k1_ec_seckey_verify(ctx, privateKey) == 1 else { return nil }
        
        var publicKeySecp = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_create(ctx, &publicKeySecp, privateKey) == 1 else { return nil }
        
        var publicKeyLength: Int = 65
        var publicKeyUncompressed = Array(repeating: Byte(0), count: publicKeyLength)
        secp256k1_ec_pubkey_serialize(ctx, &publicKeyUncompressed, &publicKeyLength, &publicKeySecp, UInt32(SECP256K1_EC_UNCOMPRESSED))
        return KeyPair(privateKey: Data(privateKey), publicKey: Data(publicKeyUncompressed))
    }
    
    public static func serializeToDer(secp256k1Signature: Data) -> Data? {
        guard let ctx = context else { return nil }
        
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, Array(secp256k1Signature)) == 1 else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
        var length: Int = 128
        var der = [UInt8].init(repeating: UInt8(0x0), count: Int(length))
        guard secp256k1_ecdsa_signature_serialize_der(ctx, &der, &length, &normalized) == 1  else { return nil }
        
        return Data(der[0..<Int(length)])
    }
    
    public static func unmarshal(secp256k1Signature: Data, hash: Data, publicKey: Data) -> (v: Data, r: Data, s: Data)? {
        guard let ctx = context else { return nil }
        
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, Array(secp256k1Signature)) == 1 else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, Array(publicKey), 65) == 1 else { return nil }
        guard secp256k1_ecdsa_verify(ctx, &normalized, Array(hash), &pubkey) == 1 else { return nil }
        
        var serialized = [UInt8].init(repeating: UInt8(0x0), count: 64)
        secp256k1_ecdsa_signature_serialize_compact(ctx, &serialized, &normalized)
        
        var recoveredSignature: Data? = nil
        for v in 27..<31 {
            let testV = UInt8(v)
            let testSign = Data(serialized + [testV])
            
            if let recoveredKey = recoverPublicKey(hash: hash, signature: testSign, compressed: false),
                recoveredKey == publicKey {
                recoveredSignature = testSign
            }
        }
        
        guard let recovered =  recoveredSignature else { return nil }
        
        if (recovered.count != 65) { return nil}
        let v = Data([recovered[64]])
        let r = Data(recovered[0..<32])
        let s = Data(recovered[32..<64])
        return (v: v, r: r, s: s)
    }
    
    public static func recoverPublicKey(hash: Data, signature: Data, compressed: Bool = false) -> Data? {
        guard hash.count == 32, signature.count == 65 else {return nil}
        guard var recoverableSignature = parseSignature(signature: signature) else {return nil}
        guard var publicKey = recoverPublicKey(hash: hash, recoverableSignature: &recoverableSignature) else {return nil}
        guard let serializedKey = serializePublicKey(publicKey: &publicKey, compressed: compressed) else {return nil}
        return serializedKey
    }
    
    static func recoverPublicKey(hash: Data, recoverableSignature: inout secp256k1_ecdsa_recoverable_signature) -> secp256k1_pubkey? {
        guard let ctx = context else { return nil }
        
        guard hash.count == 32 else {return nil}
        var publicKey: secp256k1_pubkey = secp256k1_pubkey()
        let result = hash.withUnsafeBytes({ (hashRawBufferPointer: UnsafeRawBufferPointer) -> Int32? in
            if let hashRawPointer = hashRawBufferPointer.baseAddress, hashRawBufferPointer.count > 0 {
                let hashPointer = hashRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafePointer(to: &recoverableSignature, { (signaturePointer:UnsafePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    withUnsafeMutablePointer(to: &publicKey, { (pubKeyPtr: UnsafeMutablePointer<secp256k1_pubkey>) -> Int32 in
                        let res = secp256k1_ecdsa_recover(ctx, pubKeyPtr,
                                                          signaturePointer, hashPointer)
                        return res
                    })
                })
            } else {
                return nil
            }
        })
        guard let res = result, res != 0 else {
            return nil
        }
        return publicKey
    }
    
    public static func parseSignature(signature: Data) -> secp256k1_ecdsa_recoverable_signature? {
        guard let ctx = context else { return nil }
        
        guard signature.count == 65 else {return nil}
        var recoverableSignature: secp256k1_ecdsa_recoverable_signature = secp256k1_ecdsa_recoverable_signature()
        let serializedSignature = Data(signature[0..<64])
        var v = Int32(signature[64])
        if v >= 27 && v <= 30 {
            v -= 27
        } else if v >= 31 && v <= 34 {
            v -= 31
        } else if v >= 35 && v <= 38 {
            v -= 35
        }
        let result = serializedSignature.withUnsafeBytes { (serRawBufferPtr: UnsafeRawBufferPointer) -> Int32? in
            if let serRawPtr = serRawBufferPtr.baseAddress, serRawBufferPtr.count > 0 {
                let serPtr = serRawPtr.assumingMemoryBound(to: UInt8.self)
                return withUnsafeMutablePointer(to: &recoverableSignature, { (signaturePointer:UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    let res = secp256k1_ecdsa_recoverable_signature_parse_compact(ctx, signaturePointer, serPtr, v)
                    return res
                })
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return recoverableSignature
    }
    
    static func serializeSignature(recoverableSignature: inout secp256k1_ecdsa_recoverable_signature) -> Data? {
        guard let ctx = context else { return nil }
        
        var serializedSignature = Data(repeating: 0x00, count: 64)
        var v: Int32 = 0
        let result = serializedSignature.withUnsafeMutableBytes { (serSignatureRawBufferPointer: UnsafeMutableRawBufferPointer) -> Int32? in
            if let serSignatureRawPointer = serSignatureRawBufferPointer.baseAddress, serSignatureRawBufferPointer.count > 0 {
                let serSignaturePointer = serSignatureRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafePointer(to: &recoverableSignature) { (signaturePointer:UnsafePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    withUnsafeMutablePointer(to: &v, { (vPtr: UnsafeMutablePointer<Int32>) -> Int32 in
                        let res = secp256k1_ecdsa_recoverable_signature_serialize_compact(ctx, serSignaturePointer, vPtr, signaturePointer)
                        return res
                    })
                }
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        if (v == 0 || v == 27 || v == 31 || v == 35) {
            serializedSignature.append(0x1b)
        } else if (v == 1 || v == 28 || v == 32 || v == 36) {
            serializedSignature.append(0x1c)
        } else {
            return nil
        }
        return Data(serializedSignature)
    }
    
    public static func serializePublicKey(publicKey: inout secp256k1_pubkey, compressed: Bool = false) -> Data? {
        guard let ctx = context else { return nil }
        
        var keyLength = compressed ? 33 : 65
        var serializedPubkey = Data(repeating: 0x00, count: keyLength)
        let result = serializedPubkey.withUnsafeMutableBytes { (serializedPubkeyRawBuffPointer) -> Int32? in
            if let serializedPkRawPointer = serializedPubkeyRawBuffPointer.baseAddress, serializedPubkeyRawBuffPointer.count > 0 {
                let serializedPubkeyPointer = serializedPkRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafeMutablePointer(to: &keyLength, { (keyPtr:UnsafeMutablePointer<Int>) -> Int32 in
                    withUnsafeMutablePointer(to: &publicKey, { (pubKeyPtr:UnsafeMutablePointer<secp256k1_pubkey>) -> Int32 in
                        let res = secp256k1_ec_pubkey_serialize(ctx,
                                                                serializedPubkeyPointer,
                                                                keyPtr,
                                                                pubKeyPtr,
                                                                UInt32(compressed ? SECP256K1_EC_COMPRESSED : SECP256K1_EC_UNCOMPRESSED))
                        return res
                    })
                })
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return Data(serializedPubkey)
    }
    
    public static func convertKeyToCompressed(_ walletPublicKey: Data) -> Data? {
        guard let ctx = context else { return nil }
        
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, Array(walletPublicKey), 65) == 1 else { return nil }
        
        var pubLength = 33
        var pubKeyCompressed = Array(repeating: UInt8(0), count: Int(pubLength))
        secp256k1_ec_pubkey_serialize(ctx, &pubKeyCompressed, &pubLength, &pubkey, UInt32(SECP256K1_EC_COMPRESSED))
        
        return Data(pubKeyCompressed)
        
    }
    
    public static func normalizeVerify(secp256k1Signature: Data, hash: Data, publicKey: Data) -> Data? {
        guard let ctx = context else { return nil }
        
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, Array(secp256k1Signature)) == 1 else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, Array(publicKey), 65) == 1 else { return nil }
        guard secp256k1_ecdsa_verify(ctx, &normalized, Array(hash), &pubkey) == 1 else { return nil }
        
        var serialized = [UInt8].init(repeating: UInt8(0x0), count: 64)
        secp256k1_ecdsa_signature_serialize_compact(ctx, &serialized, &normalized)
        
        return Data(serialized)
    }
    
    public static func getSharedSecret(privateKey: Data, publicKey: Data) -> Data? {
        guard let ctx = context else { return nil }
        
        let privkey = privateKey.toBytes
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, publicKey.toBytes, 65) == 1 else { return nil }
        
        var sharedSecret = Array(repeating: UInt8(0), count: 32)
        guard secp256k1_ecdh(ctx, &sharedSecret, &pubkey, privkey, nil, nil) == 1 else { return nil }
        
        return Data(sharedSecret)
    }
}
