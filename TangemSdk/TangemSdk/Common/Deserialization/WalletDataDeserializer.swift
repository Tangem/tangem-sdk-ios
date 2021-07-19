//
//  CardSerializer.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct WalletDataDeserializer {
    func deserialize(cardDataDecoder: TlvDecoder) throws -> WalletData? {
        let blockchain: String? = try cardDataDecoder.decode(.blockchainName)
        if blockchain == nil {
            return nil
        }

        return WalletData(blockchain: blockchain!,
                          token: try deserializeToken(cardDataDecoder: cardDataDecoder))
    }
    
    private func deserializeToken(cardDataDecoder: TlvDecoder) throws -> Token? {
        let tokenName: String? = try cardDataDecoder.decode(.tokenName)
        let tokenSymbol: String? = try cardDataDecoder.decode(.tokenSymbol)
        let tokenContractAddress: String? = try cardDataDecoder.decode(.tokenContractAddress)
        let tokenDecimals: Int? = try cardDataDecoder.decode(.tokenDecimal)
        
        if let tokenSymbol = tokenSymbol,
           let tokenContractAddress = tokenContractAddress,
           let tokenDecimals = tokenDecimals {
            return Token(name: tokenName ?? tokenSymbol,
                         symbol: tokenSymbol,
                         contractAddress: tokenContractAddress,
                         decimals: tokenDecimals)
        }
        
        return nil
    }
}
