//
//  FileHashHelper.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/9/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Use this helper when creating signatures for files that signed by issuer
@available(iOS 13.0, *)
public struct FileHashHelper {
	
	/// Creating hashes for `FileDataProtectedBySignature`
	/// - Parameters:
	///   - cardId: CID, Unique Tangem card ID number.
	///   - fileData: Data of file that will be saved on card
	///   - fileCounter: A counter that protect issuer data against replay attack.
	///   - privateKey: Optional private key that will be used for signing files hashes. If provided - resulting `FileHashData` will have signed file signatures
	/// - Returns: `FileHashData`
	public static func prepareHash(for cardId: String, fileData: Data, fileCounter: Int, privateKey: Data? = nil) -> FileHashData {
		let startHash = Data(hexString: cardId) + fileCounter.bytes4 + fileData.count.bytes2
		let finalHash = Data(hexString: cardId) + fileData + fileCounter.bytes4
		var startSignature: Data?
		var finalSignature: Data?
		if let privateKey = privateKey {
			startSignature = startHash.sign(privateKey: privateKey)
			finalSignature = finalHash.sign(privateKey: privateKey)
		}
		
		return FileHashData(startingHash: startHash,
							startingSignature: startSignature,
							finalizingHash: finalHash,
							finalizingSignature: finalSignature)
	}
}
