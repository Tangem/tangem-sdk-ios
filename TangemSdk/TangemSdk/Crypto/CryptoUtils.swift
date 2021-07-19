//
//  CryptoUtils.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CommonCrypto
import CryptoKit

@available(iOS 13.0, *)
public final class CryptoUtils {
    
    /**
     * Generates array of random bytes.
     * It is used, among other things, to generate helper private keys
     * (not the one for the blockchains, that one is generated on the card and does not leave the card).
     *
     * - Parameter count: length of the array that is to be generated.
     */
    public static func generateRandomBytes(count: Int) throws -> Data  {
        var bytes = [Byte](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return Data(bytes)
        } else {
            throw TangemSdkError.failedToGenerateRandomSequence
        }
    }
    
    /**
     * Helper function to verify that the data was signed with a private key that corresponds
     * to the provided public key.
     *  - Parameter curve: Elliptic curve used
     *  - Parameter publicKey: Corresponding to the private key that was used to sing a message
     *  - Parameter message: The data that was signed
     *  - Parameter signature: Signed data
     */
    public static func verify(curve: EllipticCurve, publicKey: Data, message: Data, signature: Data) -> Bool? {
        switch curve {
        case .secp256k1:
            return Secp256k1Utils.verify(publicKey: publicKey, message: message, signature: signature)
        case .ed25519:
            let hash = message.getSha512()
            let pubKey = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
            return pubKey?.isValidSignature(signature, for: hash)
        case .secp256r1:
            let pubKey = try? P256.Signing.PublicKey(x963Representation: publicKey)
            guard let sig = try? P256.Signing.ECDSASignature(rawRepresentation: signature) else { return nil }
            
            return pubKey?.isValidSignature(sig, for: message)
        }
    }
    
    public static func crypt(operation: Int, algorithm: Int, options: Int, key: Data, dataIn: Data) throws -> Data {
        return try key.withUnsafeBytes { keyUnsafeRawBufferPointer in
            return try dataIn.withUnsafeBytes { dataInUnsafeRawBufferPointer in
                // Give the data out some breathing room for PKCS7's padding.
                let dataOutSize: Int = dataIn.count + kCCBlockSizeAES128*2
                let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutSize,
                                                               alignment: 1)
                defer { dataOut.deallocate() }
                var dataOutMoved: Int = 0
                let status = CCCrypt(CCOperation(operation), CCAlgorithm(algorithm),
                                     CCOptions(options),
                                     keyUnsafeRawBufferPointer.baseAddress, key.count,
                                     nil,
                                     dataInUnsafeRawBufferPointer.baseAddress, dataIn.count,
                                     dataOut, dataOutSize, &dataOutMoved)
                guard status == kCCSuccess else { throw status }
                return Data(bytes: dataOut, count: dataOutMoved)
            }
        }
    }
}

