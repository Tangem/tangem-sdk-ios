//
//  PreflightReadTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 15/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Mode for preflight read task
/// - Note: Valid for cards with COS v.4 and higher. Older card will always read the card and the wallet info. `fullCardRead` will be used by default
@available(iOS 13.0, *)
public enum PreflightReadMode: Decodable, Equatable {
    /// No card will be read at session start. `SessionEnvironment.card` will be empty
    case none
    /// Read only card info without wallet info. COS 4+. Older card will always read card and wallet info
    case readCardOnly
    /// Read card info and single wallet associated with the specified publicKey. COS 4+. Older card will always read card and wallet info
    case readWallet(publicKey: Data)
    /// Read card info and all wallets. Used by default
    case fullCardRead
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValue = try values.decode(String.self).lowercased()
        
        switch stringValue {
        case "none":
            self = .none
        case "readcardonly":
            self = .readCardOnly
        case "fullcardread":
            self = .fullCardRead
        default:
            if stringValue.count == 64 {
                self = .readWallet(publicKey: Data(hexString: stringValue))
            } else {
                throw TangemSdkError.decodingFailed("Failed to decode PreflightReadMode")
            }
        }
    }
}

@available(iOS 13.0, *)
public final class PreflightReadTask: CardSessionRunnable {
    private let readMode: PreflightReadMode
    private let cardId: String?
    
    public init(readMode: PreflightReadMode, cardId: String?) {
        self.readMode = readMode
        self.cardId = cardId
    }
    
    deinit {
        Log.debug("PreflightReadTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        Log.debug("Run preflight read with mode: \(readMode)")
        ReadCommand().run(in: session) { result in
            switch result {
            case .success(let readResponse):
                if let expectedCardId = self.cardId?.uppercased(),
                   expectedCardId != readResponse.cardId.uppercased() {
                    completion(.failure(.wrongCardNumber))
                    return
                }
                
                if !session.environment.config.filter.isCardAllowed(readResponse) {
                    completion(.failure(.wrongCardType))
                    return
                }
                
                self.finalizeRead(in: session, with: readResponse, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func finalizeRead(in session: CardSession, with card: Card, completion: @escaping CompletionResult<Card>) {
        if card.firmwareVersion < .multiwalletAvailable {
            completion(.success(card))
            return
        }
        
        switch readMode {
        case .readWallet(let publicKey):
            readWallet(with: publicKey, in: session, with: card, completion: completion)
        case .fullCardRead:
            readWalletsList(in: session, with: card, completion: completion)
        case .readCardOnly, .none:
            completion(.success(card))
        }
    }
    
    private func readWallet(with publicKey: Data, in session: CardSession, with card: Card, completion: @escaping CompletionResult<Card>) {
        ReadWalletCommand(publicKey: publicKey).run(in: session) { (result) in
            switch result {
            case .success:
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readWalletsList(in session: CardSession, with card: Card, completion: @escaping CompletionResult<Card>) {
        ReadWalletsListCommand().run(in: session) { (result) in
            switch result {
            case .success:
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

