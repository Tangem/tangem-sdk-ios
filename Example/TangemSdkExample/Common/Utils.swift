//
//  Utils.swift
//  TangemSdkExample
//
//  Created by Andrew Son on 10/19/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct Utils {
	static var issuer: KeyPair = {
		let priv = "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92"
		let pub = "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26"
		let keyPairJson = "{\"privateKey\":\"\(priv)\",\"publicKey\":\"\(pub)\"}".data(using: .utf8)
		let jsonDecoder = JSONDecoder.tangemSdkDecoder
		let keyPair = try! jsonDecoder.decode(KeyPair.self, from: keyPairJson!)
		return keyPair
	}()
	
	static func signDataWithIssuer(_ data: Data) -> Data? {
		data.sign(privateKey: issuer.privateKey, curve: .secp256k1)
	}
	
}
