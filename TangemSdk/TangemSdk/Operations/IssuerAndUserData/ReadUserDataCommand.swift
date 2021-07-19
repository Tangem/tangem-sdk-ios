//
//  ReadUserDataCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `ReadUserDataCommand`.
public struct ReadUserDataResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Data defined by user's App.
    public let userData: Data
    ///Data defined by user's App (confirmed by PIN2).
    public let userProtectedData: Data
    ///Counter initialized by user's App and increased on every signing of new transaction
    public let userCounter: Int
    ///* Counter initialized by user's App (confirmed by PIN2) and increased on every signing of new transaction
    public let userProtectedCounter: Int
}

/**
 * This command returns two up to 512-byte User_Data, User_Protected_Data and two counters User_Counter and
 * User_Protected_Counter fields.
 * User_Data and User_ProtectedData are never changed or parsed by the executable code the Tangem COS.
 * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
 * from blockchain to accelerate preparing new transaction.
 * User_Counter and User_ProtectedCounter are counters, that initial values can be set by App and increased on every signing
 * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
 * For example, this fields may contain blockchain nonce value.
 */
@available(*, deprecated, message: "Use files instead")
@available(iOS 13.0, *)
public final class ReadUserDataCommand: Command {
    public init() {}
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion >= .filesAvailable {
            return .notSupportedFirmwareVersion
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
        
        return CommandApdu(.readUserData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadUserDataResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return ReadUserDataResponse(cardId: try decoder.decode(.cardId),
                                    userData: try decoder.decode(.userData),
                                    userProtectedData: try decoder.decode(.userProtectedData),
                                    userCounter: try decoder.decode(.userCounter),
                                    userProtectedCounter: try decoder.decode(.userProtectedCounter)
        )
    }
}
