//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// This command deletes all wallet data and its private and public keys
@available(iOS 13.0, *)
public final class PurgeWalletCommand: Command {
    public var preflightReadMode: PreflightReadMode { .readWallet(publicKey: walletPublicKey) }
    
    var requiresPasscode: Bool { return true }
    
    private let walletPublicKey: Data
    
    /// Default initializer
    /// - Parameter publicKey: Public key of the wallet to delete
    public init(publicKey: Data) {
		self.walletPublicKey = publicKey
	}
    
    deinit {
        Log.debug("PurgeWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard let wallet = card.wallets[walletPublicKey] else {
            return .walletNotFound
        }
        
        if wallet.settings.isPermanent {
            return .purgeWalletProhibited
        }
        
        return nil
    }
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
		transceive(in: session) { (result) in
			switch result {
			case .success(let response):
                session.environment.card?.wallets[self.walletPublicKey] = nil
				completion(.success(response))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.walletPublicKey, value: walletPublicKey)
		
        return CommandApdu(.purgeWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
