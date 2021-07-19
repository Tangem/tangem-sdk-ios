//
//  String+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public extension String {
    var titleFormatted: String {
        let separator = Array(repeating: "-", count: 16).joined()
        return "\(separator) \(self) \(separator)"
    }
    
    func remove(_ substring: String) -> String {
        return self.replacingOccurrences(of: substring, with: "")
    }
    
    func sha256() -> Data {
        let data = Data(Array(utf8))
        return data.getSha256()
    }
    
    func sha512() -> Data {
        let data = Data(Array(utf8))
        return data.getSha512()
    }
    
    internal func capitalizingFirst() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    internal func lowercasingFirst() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
    
    internal var localized: String {
        Localization.getFormat(for: self)
    }
    
    internal func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    internal func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self.processCamelCaseRegex(pattern: acronymPattern)?
            .processCamelCaseRegex(pattern: normalPattern)?.lowercased() ?? self.lowercased()
    }
    
    private func processCamelCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}

@available(iOS 13.0, *)
extension DefaultStringInterpolation {
    mutating func appendInterpolation(_ data: Data) {
        appendLiteral(data.hexString)
    }
    
    mutating func appendInterpolation(_ byte: Byte) {
        appendLiteral(byte.hexString)
    }
}
