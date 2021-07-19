
//
//  CARD.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

@available(iOS 13.0, *)
protocol ApduSerializable {
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse
    
    /// Serializes data into an array of `Tlv`, then creates `CommandApdu` with this data.
    /// - Parameter environment: `SessionEnvironment` of the current card
    /// - Returns: Command data that can be converted to `NFCISO7816APDU` with appropriate initializer
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu
    
    /// Deserializes data, received from a card and stored in `ResponseApdu`  into an array of `Tlv`. Then this method maps it into a `CommandResponse`.
    /// - Parameters:
    ///   - environment: `SessionEnvironment` of the current card
    ///   - apdu: Received data
    /// - Returns: Card response, converted to a `CommandResponse` of a type `T`.
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CommandResponse
}

@available(iOS 13.0, *)
extension ApduSerializable {
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    /// 4 - Timeout setting for ping nfc-module
    func createTlvBuilder(legacyMode: Bool) -> TlvBuilder {
        let builder = TlvBuilder()
        if legacyMode {
            try! builder.append(.legacyMode, value: 4)
        }
        return builder
    }
}

/// The basic protocol for card commands
@available(iOS 13.0, *)
protocol Command: AnyObject, ApduSerializable, CardSessionRunnable {
    /// If set to `true` and ` SessionEnvironment.passcode` is nil, pin2 will be requested automatically before transieve the apdu. Default is `false`
    var requiresPasscode: Bool { get }
    
    func performPreCheck(_ card: Card) -> TangemSdkError?
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError
}

@available(iOS 13.0, *)
extension Command {
    var requiresPasscode: Bool { return false }

    public func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        transceive(in: session, completion: completion)
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        return nil
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        return error
    }

    func transceive(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        let commandName = "\(self)".remove("TangemSdk.").remove("Command")
        Log.command("=======================") //TODO: refactor
        Log.command("Send command: \(commandName)")
        Log.command("=======================")
        if preflightReadMode != .none && session.environment.card == nil {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if session.environment.config.handleErrors, let card = session.environment.card {
            if let error = performPreCheck(card) {
                completion(.failure(error))
                return
            }
        }
        
        if session.environment.passcode.value == nil && requiresPasscode {
           requestPin(.passcode, session, completion: completion)
        } else {
           transceiveInternal(in: session, completion: completion)
        }
    }
    
    private func transceiveInternal(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        do {
            session.rememberTag()
            Log.apdu("----Serialize command:-----")
            let commandApdu = try serialize(with: session.environment)
            Log.apdu("---------------------------")
            transceive(apdu: commandApdu, in: session) { result in
                session.releaseTag()
                switch result {
                case .success(let responseApdu):
                    do {
                        Log.apdu("-----Deserialize response:-----")
                        let responseData = try self.deserialize(with: session.environment, from: responseApdu)
                        Log.apdu("-------------------------------")
                        completion(.success(responseData))
                    } catch {
                        completion(.failure(error.toTangemSdkError()))
                    }
                case .failure(let error):
                    if session.environment.config.handleErrors {
                        let mappedError = self.mapError(session.environment.card, error)
                        switch mappedError {
                        case .accessCodeRequired:
                            self.requestPin(.accessCode, session, completion: completion) //only read command
                        case .invalidParams:
                            if self.requiresPasscode {
                                //Addition check for COS v4 and newer to prevent false-positive pin2 request
                                if session.environment.card?.isPasscodeSet == false,
                                   !session.environment.isUserCodeSet(.passcode) {
                                    fallthrough
                                }
                                
                                self.requestPin(.passcode, session, completion: completion)
                            } else { fallthrough }
                        default:
                            completion(.failure(mappedError))
                        }
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    private func transceive(apdu: CommandApdu, in session: CardSession, completion: @escaping CompletionResult<ResponseApdu>) {
        session.send(apdu: apdu) { result in
            switch result {
            case .success(let responseApdu):
                switch responseApdu.statusWord {
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed,
                     .pins12Changed, .pins13Changed, .pins23Changed, .pins123Changed:
					session.viewDelegate.showUndefinedSpinner()
                    completion(.success(responseApdu))
                case .needPause:
                    if let securityDelayResponse = self.deserializeSecurityDelay(with: session.environment, from: responseApdu) {
                        session.viewDelegate.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds, message: nil, hint: nil)
                        if securityDelayResponse.saveToFlash && session.environment.encryptionMode == .none {
                            session.restartPolling()
                        }
                        self.transceive(apdu: apdu, in: session, completion: completion)                        
                    }
                case .needEcryption:
                    switch session.environment.encryptionMode {
                    case .none:
                        Log.session("Try change to fast encryption")
                        session.environment.encryptionKey = nil
                        session.environment.encryptionMode = .fast
                    case .fast:
                        Log.session("Try change to strong encryption")
                        session.environment.encryptionKey = nil
                        session.environment.encryptionMode = .strong
                    case .strong:
                        break
                    }
                    self.transceive(apdu: apdu, in: session, completion: completion)
                case .unknown:
                    completion(.failure(.unknownStatus(responseApdu.sw.hexString)))
                default:
                    completion(.failure(responseApdu.statusWord.toTangemSdkError() ?? .unknownError))
                }
            case .failure(let error):
				session.viewDelegate.hideUI(nil)
                completion(.failure(error))
            }
        }
    }
    
    /// Helper method to parse security delay information received from a card.
    /// - Returns: Remaining security delay in milliseconds.
    private func deserializeSecurityDelay(with environment: SessionEnvironment, from responseApdu: ResponseApdu) -> (remainingMilliseconds: Int, saveToFlash: Bool)? {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey),
            let remainingMilliseconds = tlv.value(for: .pause)?.toInt() else {
                return nil
        }
        
        let saveToFlash = tlv.contains(tag: .flash)
        return (remainingMilliseconds, saveToFlash)
    }
    
    private func requestPin(_ type: UserCodeType, _ session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        session.pause(error: TangemSdkError.from(userCodeType: type, environment: session.environment))
        
        switch type {
        case .accessCode:
            session.environment.accessCode = UserCode(.accessCode, value: nil)
        case .passcode:
            session.environment.passcode = UserCode(.passcode, value: nil)
        }
        
        DispatchQueue.main.async {
            session.requestUserCodeIfNeeded(type) { result in
                switch result {
                case .success:
                    session.resume()
                    self.transceiveInternal(in: session, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
