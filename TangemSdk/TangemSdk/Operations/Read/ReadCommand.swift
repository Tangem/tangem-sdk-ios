//
//  ReadCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// This command receives from the Tangem Card all the data about the card and the wallet,
///  including unique card number (CID or cardId) that has to be submitted while calling all other commands.
@available(iOS 13.0, *)
final class ReadCommand: Command {
    var preflightReadMode: PreflightReadMode { .none }
    
    deinit {
        Log.debug("ReadCommand deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.card = response.0
                session.environment.walletData = response.1
                completion(.success(response.0))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            return .accessCodeRequired
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        /// `SessionEnvironment` stores the pin1 value. If no pin1 value was set, it will contain
        /// default value of ‘000000’.
        /// In order to obtain card’s data, [ReadCommand] should use the correct pin 1 value.
        /// The card will not respond if wrong pin 1 has been submitted.
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.interactionMode, value: ReadMode.card)
        if let keys = environment.terminalKeys {
            try tlvBuilder.append(.terminalPublicKey, value: keys.publicKey)
        }
        
        
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> (Card, WalletData?) {
        let decoder = try CardDeserializer.getDecoder(with: environment, from: apdu)
        let cardDataDecoder = try CardDeserializer.getCardDataDecoder(with: environment, from: decoder.tlv)
        let card = try CardDeserializer().deserialize(decoder: decoder, cardDataDecoder: cardDataDecoder)
        let walletData = try cardDataDecoder.flatMap { try WalletDataDeserializer().deserialize(cardDataDecoder: $0) }
        return (card, walletData)
    }
}
