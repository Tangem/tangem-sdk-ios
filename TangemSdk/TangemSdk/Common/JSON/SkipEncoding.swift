//
//  SkipEncoding.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 01.07.2021.
//  Copyright © 2020 Tangem AG. All rights reserved.
//
import Foundation

/// Add this to a Property to not included it when Encoding
@propertyWrapper
struct SkipEncoding<WrappedType: Codable>: EncodeSkippable {
    var wrappedValue: WrappedType
    
    init(wrappedValue: WrappedType) {
        self.wrappedValue = wrappedValue
    }
}

/// Protocol to indicate instances should be skipped when encoding
protocol EncodeSkippable: Codable {
    associatedtype WrappedType: Decodable
    
    init(wrappedValue: WrappedType)
}

extension EncodeSkippable {
    // This shouldn't ever be called since KeyedEncodingContainer should skip it due to the included extension
    func encode(to encoder: Encoder) throws { return }
    
    init(from decoder: Decoder) throws {
        let value = try WrappedType(from: decoder)
        self.init(wrappedValue: value)
    }
}

extension KeyedDecodingContainer {
    // This is used to override the default decoding behavior for OptionalCodingWrapper to allow a value to avoid a missing key Error
    func decode<T: EncodeSkippable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T where T.WrappedType: ExpressibleByNilLiteral {
        return try decodeIfPresent(T.self, forKey: key) ?? T(wrappedValue: nil)
    }
}

extension KeyedEncodingContainer {
    // Used to make make sure OmitableFromEncoding never encodes a value
    mutating func encode<T: EncodeSkippable>(_ value: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        return
    }
}

//MARK: - Conditional Equatable Conformance
extension SkipEncoding: Equatable where WrappedType: Equatable { }

//MARK: - Conditional Hashable Conformance
extension SkipEncoding: Hashable where WrappedType: Hashable { }
