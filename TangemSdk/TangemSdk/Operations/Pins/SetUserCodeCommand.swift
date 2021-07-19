//
//  SetUserCodeCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class SetUserCodeCommand: Command {
    var requiresPasscode: Bool { return true }
    private var shouldRestrictDefaultCodes = true
    
    private var codes: [UserCodeType: UserCodeAction] = [:]
    
    /// Change access code only. Passcode will be remain the same
    /// - Parameters:
    ///   - accessCode: If nil, user will be prompted to enter the code
    public init(accessCode: String?) {
        codes[.accessCode] = accessCode.map{ .stringValue($0) } ?? .request
        codes[.passcode] = .notChange
    }
    
    /// Change  passcode only. Access code will be remain the same
    /// - Parameters:
    ///   - passcode: If nil, user will be prompted to enter the code
    public init(passcode: String?) {
        codes[.accessCode] = .notChange
        codes[.passcode] = passcode.map{ .stringValue($0) } ?? .request
    }
    
    /// Change  access code and passcode.
    /// - Parameters:
    ///   - accessCode: If nil, user will be prompted to enter the code
    ///   - passcode: If nil, user will be prompted to enter the code
    public init(accessCode: String?, passcode: String?) {
        codes[.accessCode] = accessCode.map{ .stringValue($0) } ?? .request
        codes[.passcode] = passcode.map{ .stringValue($0) } ?? .request
    }
    
    /// Change  access code and passcode. Useful for checkpin, because with take codes from environment as Data
    /// - Parameters:
    ///   - accessCode: If nil, user will be prompted to enter the code
    ///   - passcode: If nil, user will be prompted to enter the code
    init(accessCode: Data?, passcode: Data?) {
        codes[.accessCode] = accessCode.map{ .value($0) } ?? .request
        codes[.passcode] = passcode.map{ .value($0) } ?? .request
    }
    
    deinit {
        Log.debug("SetPinCommand deinit")
    }

    public func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>) {
        requestIfNeeded(.accessCode, in: session) { result  in
            switch result {
            case .success:
                self.requestIfNeeded(.passcode, in: session) { result  in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        if codes.values.contains(.request) { //If prepare not called e.g. chaining
            if let error = getPauseError(environment: session.environment) {
                session.pause(error: error)
            } else {
                session.pause()
            }
            
            prepare(session) { result in
                switch result {
                case .success:
                    session.resume()
                    self.runCommand(in: session, completion: completion )
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            self.runCommand(in: session, completion: completion )
        }
    }
    
    private func runCommand(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        //Restrict default codes except reset command
        if self.shouldRestrictDefaultCodes,
           !self.isCodeAllowed(.accessCode) || !self.isCodeAllowed(.passcode) {
            completion(.failure(TangemSdkError.passcodeCannotBeChanged))
            return
        }
        
        self.transceive(in: session, completion: completion )
    }
    
    private func isCodeAllowed(_ type: UserCodeType) -> Bool  {
        if let code = self.codes[type]?.value,
           code == type.defaultValue.sha256() {
            return false
        }
        
        return true
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.newPin, value: codes[.accessCode]?.value ?? environment.accessCode.value)
            .append(.newPin2, value: codes[.passcode]?.value ?? environment.passcode.value)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        return CommandApdu(.setPin, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
    
    private func getPauseError(environment: SessionEnvironment) -> TangemSdkError? {
        let filtered = codes.filter { $0.value == .request }
        
        guard filtered.count == 1, let type = filtered.first?.key else {
            return nil
        }
        
        return TangemSdkError.from(userCodeType: type, environment: environment)
    }
    
    private func requestIfNeeded(_ type: UserCodeType, in session: CardSession, completion: @escaping CompletionResult<Void>) {
        guard codes[type] == .request else {
            completion(.success(()))
            return
        }
        
        session.viewDelegate.requestUserCodeChange(type: type, cardId: session.cardId) { result in
            switch result {
            case .success(let pinChangeResult):
                self.codes[type] = .stringValue(pinChangeResult.newCode)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
// MARK:- Reset codes
@available(iOS 13.0, *)
public extension SetUserCodeCommand {
    static var resetAccessCodeCommand: SetUserCodeCommand {
        let command = SetUserCodeCommand(accessCode: UserCodeType.accessCode.defaultValue)
        command.shouldRestrictDefaultCodes = false
        return command
    }
    
    static var resetPasscodeCommand: SetUserCodeCommand {
        let command = SetUserCodeCommand(passcode: UserCodeType.passcode.defaultValue)
        command.shouldRestrictDefaultCodes = false
        return command
    }
    
    static var resetUserCodes: SetUserCodeCommand {
        let command = SetUserCodeCommand(accessCode: UserCodeType.accessCode.defaultValue,
                                         passcode: UserCodeType.passcode.defaultValue)
        command.shouldRestrictDefaultCodes = false
        return command
    }
}

@available(iOS 13.0, *)
extension SetUserCodeCommand {
    enum UserCodeAction: Equatable {
        case request
        case stringValue(String)
        case value(Data)
        case notChange
        
        var value: Data? {
            switch self {
            case .stringValue(let code):
                return code.sha256()
            case .value(let code):
                return code
            default:
                return nil
            }
        }
    }
}
