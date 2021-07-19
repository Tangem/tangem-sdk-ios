//
//  VerifyCardRequest.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct CardVerifyAndGetInfoRequest: Codable {
    
    public struct Item: Codable {
        let cardId: String
        let publicKey: String
        
        enum CodingKeys: String, CodingKey {
            case cardId = "CID"
            case publicKey
        }
    }
    
    let requests: [Item]
}

public struct CardVerifyAndGetInfoResponse: Codable {
    
    public struct Item: Codable {
        public let error: String?
        public let cardId: String
        public let passed: Bool
        public let batch: String?
        public let artwork: ArtworkInfo?
        public let substitution: SubstitutionInfo?
        
        enum CodingKeys: String, CodingKey {
            case cardId = "CID"
            case artwork
            case batch
            case passed
            case error
            case substitution
        }
    }
    
    public let results: [Item]
}

public struct SubstitutionInfo: Codable {
    
    public struct CardSubstitutionDataModel: Codable {
        let tokenSymbol: String?
        let tokenContractAddress: String?
        let tokenDecimal: Int?
        
        enum CodingKeys: String, CodingKey {
            case tokenSymbol = "token_symbol"
            case tokenContractAddress = "token_contract_address"
            case tokenDecimal = "token_decimal"
        }
    }
    
    let data: String?
    let signature: String?
    
    var substutionData: CardSubstitutionDataModel? {
        if let data = data?.data(using: .utf8),
            let model = try? JSONDecoder().decode(CardSubstitutionDataModel.self, from: data) {
            return model
        }
        return nil
    }
}

public struct ArtworkInfo: Codable, Equatable {
    public let id: String
    public let hash: String
    public let date: String
    
    public var updateDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter.date(from: date)
    }
}
