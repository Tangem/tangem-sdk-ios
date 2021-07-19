//
//  SignHashCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 21.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Response for `SignHashCommand`.
public struct SignHashResponse: JSONStringConvertible {
    /// CID, Unique Tangem card ID number
    public let cardId: String
    /// Signed hash
    public let signature: Data
    /// Total number of signed  hashes returned by the wallet since its creation. COS: 1.16+
    public let totalSignedHashes: Int?
}

@available(iOS 13.0, *)
public final class SignHashCommand: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode { .readWallet(publicKey: walletPublicKey) }
    
    private let walletPublicKey: Data
    private let hash: Data
    
    /// Default initializer
    /// - Parameters:
    ///   - hash: Transaction hash for sign by card.
    ///   - walletPublicKey: Public key of the wallet, using for sign.
    public init(hash: Data, walletPublicKey: Data) {
        self.hash = hash
        self.walletPublicKey = walletPublicKey
    }
    
    deinit {
        Log.debug("SignHashCommand deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SignHashResponse>) {
        let signCommand = SignCommand(hashes: [hash], walletPublicKey: walletPublicKey)
        signCommand.run(in: session) { result in
            switch result {
            case .success(let signResponse):
                completion(.success(SignHashResponse(signResponse)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension SignHashResponse {
    init(_ response: SignResponse) {
        cardId = response.cardId
        signature = response.signatures[0]
        totalSignedHashes = response.totalSignedHashes
    }
}
