//
//  SLIX+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

@available(iOS 13.0, *)
private protocol SlixTagReader {
    func readSlix2Tag(_ tag: NFCISO15693Tag, completion: @escaping (Result<Data, TangemSdkError>) -> Void)
}

@available(iOS 13.0, *)
extension NFCReader: SlixTagReader {
    func readSlix2Tag(_ tag: NFCISO15693Tag, completion: @escaping (Result<Data, TangemSdkError>) -> Void) {
        tag.readMultipleBlocks(requestFlags: [.highDataRate], blockRange: NSRange(location: 0, length: 40)) { [weak self] data1, error in
            if let error = error as NSError? {
                Log.nfc(error.userInfo)
                Log.nfc(error.localizedDescription)
                self?.readSlix2Tag(tag, completion: completion)
            } else {
                tag.readMultipleBlocks(requestFlags: [.highDataRate], blockRange: NSRange(location: 40, length: 38)) {[weak self] data2, error in
                    if let error = error as NSError? {
                        Log.nfc(error.userInfo)
                        Log.nfc(error.localizedDescription)
                        self?.readSlix2Tag(tag, completion: completion)
                    } else {
                        let joinedData = Data((data1 + data2).joined())
                        completion(.success(joinedData))
                    }
                }
            }
        }
    }
}

//Slix2 tag support. TODO: Refactor. Useful for payload retrieve
@available(iOS 13.0, *)
private extension ResponseApdu {
    init?(slix2Data: Data) {
        let ndefTlvData = slix2Data[4...] //cut e1402801 (CC)
        if let ndefTlv = Tlv.deserialize(ndefTlvData),
           let ndefValue = ndefTlv.value(for: .cardPublicKey),
           let ndefMessage = NFCNDEFMessage(data: Data(ndefValue)) {
            let payloads = ndefMessage.records.filter({ String(data: $0.type, encoding: String.Encoding.utf8) == "tangem.com:wallet"})
            if let payload = payloads.first?.payload  {
                self.init(payload, Byte(0x90), Byte(0x00))
                return
            }
        }
        return nil
    }
}
