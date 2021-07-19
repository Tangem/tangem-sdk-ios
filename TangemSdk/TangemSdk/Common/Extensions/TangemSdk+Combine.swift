//
//  ResponseApdu+Combine.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 04.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CoreNFC

@available(iOS 13.0, *)
extension ResponseApdu {
    func decryptPublisher(encryptionKey: Data?) -> AnyPublisher<ResponseApdu, TangemSdkError> {
        return Deferred {Future() { promise in
            do {
                let decrypted = try self.decrypt(encryptionKey: encryptionKey)
                promise(.success(decrypted))
            } catch {
                promise(.failure(error.toTangemSdkError()))
            }
        }}.eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension CommandApdu {
    func encryptPublisher(encryptionMode: EncryptionMode, encryptionKey: Data?) -> AnyPublisher<CommandApdu, TangemSdkError> {
        return Deferred {Future() { promise in
            do {
                let encrypted = try self.encrypt(encryptionMode: encryptionMode, encryptionKey: encryptionKey)
                promise(.success(encrypted))
            } catch {
                promise(.failure(error.toTangemSdkError()))
            }
        }}.eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension NFCISO7816Tag {
    func sendCommandPublisher(cApdu: CommandApdu) -> AnyPublisher<ResponseApdu, TangemSdkError> {
        return Deferred { Future() {[unowned self] promise in
            let requestDate = Date()
            
            self.sendCommand(apdu: NFCISO7816APDU(cApdu)) { data, sw1, sw2, error in
                if let sdkError = error?.toTangemSdkError() {
                    Log.error(sdkError)
                    promise(.failure(sdkError))
                } else {
                    let dateDiff = Calendar.current.dateComponents([.nanosecond], from: requestDate, to: Date())
                    Log.command("Command execution time is: \((dateDiff.nanosecond ?? 0)/1000000) ms")
                    
                    let rApdu = ResponseApdu(data, sw1, sw2)
                    promise(.success(rApdu))
                }
            }
        }}.eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension NFCTagReaderSession {
    func connectPublisher(tag: NFCTag) -> AnyPublisher<Void, TangemSdkError> {
        return Deferred { Future() {[unowned self] promise in
            self.connect(to: tag) { error in
                if let error = error {
                    promise(.failure(error.toTangemSdkError()))
                } else {
                    promise(.success(()))
                }
            }
        }}.eraseToAnyPublisher()
    }
}
