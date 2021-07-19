//
//  CheckPinCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct CheckUserCodesResponse: JSONStringConvertible {
    public let isAccessCodeSet: Bool
    public let isPasscodeSet: Bool
}

@available(iOS 13.0, *)
public final class CheckUserCodesCommand: CardSessionRunnable {
    public init() {}
    
    deinit {
        Log.debug("CheckUserCodesCommand deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CheckUserCodesResponse>) {
        let command = SetUserCodeCommand(accessCode: session.environment.accessCode.value,
                                    passcode: session.environment.passcode.value)
        
        command.run(in: session) { result in
            switch result {
            case .success:
                completion(.success(CheckUserCodesResponse(isAccessCodeSet: session.environment.isUserCodeSet(.accessCode),
                                                           isPasscodeSet: session.environment.isUserCodeSet(.passcode))))
            case .failure(let error):
                if case .invalidParams = error {
                    completion(.success(CheckUserCodesResponse(isAccessCodeSet: session.environment.isUserCodeSet(.accessCode),
                                                               isPasscodeSet: true)))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}
