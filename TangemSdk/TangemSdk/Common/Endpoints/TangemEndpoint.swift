//
//  TangemEndpoint.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public enum TangemEndpoint: NetworkEndpoint {
    case verifyAndGetInfo(request: CardVerifyAndGetInfoRequest)
    case artwork(cid: String, cardPublicKey: Data, artworkId: String)
    
    private var baseURL: String {
        return "https://verify.tangem.com/"
    }
    
    public var url: URL {
        switch self {
        case .verifyAndGetInfo:
            return URL(string: baseURL + "card/verify-and-get-info")!
        case .artwork(let cid, let cardPublicKey, let artworkId):
            let parameters = ["CID" : cid,
                              "publicKey" : cardPublicKey.hexString,
                              "artworkId" : artworkId]
            
            var components = URLComponents(string: baseURL + "card/artwork")!
            components.queryItems = parameters.map { (key, value) in
                URLQueryItem(name: key, value: value)
            }
            return components.url!
        }
    }
    
    public var method: String {
        switch self {
        case .verifyAndGetInfo:
            return "POST"
        case .artwork:
            return "GET"
        }
    }
    
    public var body: Data? {
        switch self {
        case .verifyAndGetInfo(let request):
            return try? JSONEncoder().encode(request)
        case .artwork:
            return nil
        }
    }
    
    public var headers: [String : String] {
        return ["application/json" : "Content-Type"]
    }
}

