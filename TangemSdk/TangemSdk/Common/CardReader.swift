//
//  CardReader.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

public protocol CardReader: class {
    /// For setting alertMessage into NFC popup
    var alertMessage: String {get set}
    
    func startSession()
    func stopSession()
    func send(commandApdu: CommandApdu, completion: @escaping (CompletionResult<ResponseApdu,NFCReaderError>) -> Void)
    func restartPolling()
}

class CardReaderFactory {
    static func createDefaultReader() -> CardReader {
        if #available(iOS 13.0, *) {
            return NFCReader()
        } else {
            return NDEFReader()
        }
    }
}
