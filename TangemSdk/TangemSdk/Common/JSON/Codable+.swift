//
//  JSONDecoder+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension JSONDecoder {
    public static var tangemSdkDecoder: JSONDecoder  {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let hex = try container.decode(String.self)
            return Data(hexString: hex)
        }
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy  = .formatted(.tangemSdkDateFormatter)
        return decoder
    }
}

@available(iOS 13.0, *)
extension JSONEncoder {
    public static var tangemSdkEncoder: JSONEncoder  {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        encoder.dataEncodingStrategy = .custom{ data, encoder in
            var container = encoder.singleValueContainer()
            return try container.encode(data.hexString)
        }
        
        encoder.dateEncodingStrategy = .formatted(.tangemSdkDateFormatter)
        return encoder
    }
    
    public static var tangemSdkTestEncoder: JSONEncoder  {
        let encoder = JSONEncoder.tangemSdkEncoder
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

@available(iOS 13.0, *)
fileprivate extension DateFormatter {
    static var tangemSdkDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter
    }
}
