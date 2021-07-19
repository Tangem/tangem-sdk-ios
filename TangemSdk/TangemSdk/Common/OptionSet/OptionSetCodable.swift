//
//  OptionSetCodable.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
protocol OptionKey: CaseIterable, RawRepresentable where RawValue == String {
    associatedtype SomeOptionSet: OptionSet
    
    var value: SomeOptionSet { get }
}

@available(iOS 13.0, *)
protocol OptionSetCodable: Codable where Self: OptionSet {
    associatedtype OptionKeys: OptionKey
}

@available(iOS 13.0, *)
extension OptionSetCodable where OptionKeys.SomeOptionSet == Element,
                                 Self.RawValue: Decodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var values = [String]()
        
        for item in OptionKeys.allCases {
            if contains(item.value) {
                values.append(item.rawValue.capitalizingFirst())
            }
        }
        
        try container.encode(values)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        
        //try decode from raw value. (e.g. from CardConfig)
        do {
            let rawValue = try values.decode(RawValue.self)
            self = .init(rawValue: rawValue)
            return
        } catch {}
        
        //try decode string array
        let stringValues = (try values.decode([String].self)).map { $0.lowercased() }
        var optionSet = Self()
        
        for item in OptionKeys.allCases {
            if stringValues.contains(item.rawValue.lowercased()) {
                optionSet.update(with: item.value)
            }
        }
        
        self = optionSet
    }
}
