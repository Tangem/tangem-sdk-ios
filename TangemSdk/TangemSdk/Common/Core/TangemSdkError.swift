//
//  TangemSdkError.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.03.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/**
 * An error class that represent typical errors that may occur when performing Tangem SDK tasks.
 * Errors are propagated back to the caller in callbacks.
 */
@available(iOS 13.0, *)
public enum TangemSdkError: Error, LocalizedError, Encodable {
    //MARK: NFC processing errors
    
    /// This error is returned when  NFC reader loses a tag
    /// (e.g. a user detaches card from the phone's NFC module) while the NFC session is in progress.
    case tagLost
    
    /// Command was sent to wrong tag type
    case unsupportedCommand
    
    /// This error is returned when the current device doesn't support the desired NFC operations
    case unsupportedDevice
    
    /// Start session before
    case sessionInactive
    
    /// It seems that NFC does not work properly on your iPhone. Try to reboot your iPhone
    case nfcStuck
    
    case nfcTimeout
    
    case nfcReaderError

    
    //MARK: Apdu processing errrors
    
    case serializeCommandError
    
    /// This error is returned when the `ResponseApdu` cannot deserialize bytes to `[Tlv]`
    case deserializeApduFailed
    
    /// This error is returned when the `TlvEncoder` failed to encode value not matching `TlvTag` value type
    case encodingFailedTypeMismatch(_ message: String)
    
    /// This error is returned when the `TlvEncoder` failed to encode nil value or failed to encode stiring with utf8 encoding
    case encodingFailed(_ message: String)
    
    /// This error is returned when the `TlvDecoder` cannot find desired tag. You can use `decode` to handle this error automatically
    case decodingFailedMissingTag(_ message: String)
    
    /// This error is returned when the `TlvDecoder` failed to decode value not matching `TlvTag` value type
    case decodingFailedTypeMismatch(_ message: String)
    
    /// This error is returned when the `TlvDecoder` failed to decode value. Please let us know
    case decodingFailed(_ message: String)
    
    case failedToEncryptApdu
    
    case failedToDecryptApdu
    
    case failedToEstablishEncryption
    
    case invalidResponseApdu
    
    //MARK: Card errors
    
    /// This error is returned when unknown `StatusWord` is received from a card.
    case unknownStatus(_ sw: String)
    
    /// This error is returned when a card's reply is `StatusWord.ErrorProcessingCommand`.
    /// The card sends this status in case of internal card error
    case errorProcessingCommand
    
    /// This error is returned when a card's reply is `StatusWord.InvalidState`.
    /// The card sends this status when command can not be executed in the current state of a card.
    case invalidState
    
    /// This error is returned when a card's reply is `StatusWord.InsNotSupported`.
    /// The card sends this status when the card cannot process the `Instruction`.
    case insNotSupported
    
    /// This error is returned when a card's reply is `StatusWord.InvalidParams`.
    /// The card sends this status when there are wrong or not sufficient parameters in `TLV` request, or wrong `PIN1/PIN2`.
    /// The error may be caused, for example, by wrong parameters of the `ApduSerializable`, encode/decode  errors.
    case invalidParams
    
    /// This error is returned when a card's reply is `StatusWord.NeedEncryption` and the encryption was not established by TangemSdk.
    case needEncryption
    
    
    //MARK: Business logic errors
    
    // Personalization Errors
    case alreadyPersonalized
    
    // Depersonalization Errors
    case cannotBeDepersonalized
    
    // Read Errors
    case accessCodeRequired
    
    // CreateWallet Errors
    case alreadyCreated
    case unsupportedCurve //todo: localize
    case unsupportedWalletConfig //todo: localize
    
    // PurgeWallet Errors
    case purgeWalletProhibited
    
    // SetPin Errors
    case accessCodeCannotBeChanged
    case passcodeCannotBeChanged
    case accessCodeCannotBeDefault
    
    //Sign Errors
    case noRemainingSignatures
    case oldCard
    
    /// This error is returned when a `SignCommand` receives only empty hashes for signature.
    case emptyHashes
    
    /// This error is returned when a `SignCommand` receives hashes of different lengths for signature.
    case hashSizeMustBeEqual
    
    case walletIsNotCreated
    
    case signHashesNotAvailable
    
    /// Tangem cards can sign currently up to 10 hashes during one `SignCommand`.
    /// This error is returned when a `SignCommand` receives more than 10 hashes to sign.
    case tooManyHashesInOneTransaction
    
    // Write Extra Issuer Data Errors
    case extendedDataSizeTooLarge
    
    // General Errors
    
    case notPersonalized
    
    case notActivated
    
    case walletIsPurged
    
    case passcodeRequired
    
    /// This error is returned when SDK checks unsuccessfully either
    /// a card's ability to sign with its private key, or the validity of issuer data.
    case verificationFailed
    
    case cardVerificationFailed
    
    /// This error is returned when a [Task] checks unsuccessfully either
    /// a card's ability to sign with its private key, or the validity of issuer data.
    case dataSizeTooLarge
    
    /// This error is returned when `ReadIssuerData` or `ReadIssuerExtraData` expects a counter
    /// (when the card's requires it), but the counter is missing.
    case missingCounter
    
    case overwritingDataIsProhibited
    
    case dataCannotBeWritten
    
    /// This error is returned when `issuerPublicKey` requires to perform operation
    case missingIssuerPublicKey
    
    ///User entered wrong Access Code
    case wrongAccessCode
    
    ///User entered wrong Passcode
    case wrongPasscode
    
    //MARK: SDK errors
    
    case unknownError
    
    case underlying(error: Error)
    
    /// This error is returned when a user manually closes the NFC  Dialog.
    case userCancelled
    
    /// This error is returned when `CardSession`  was called with a new operation,  while a previous operation is still in progress.
    case busy
    
    /// This error is returned when a `CardSessionRunnable` requires that `ReadCommand`
    /// is executed before performing other commands.
    case missingPreflightRead
    
    /// This error is returned when a [Task] expects a user to use a particular card,
    /// but the user tries to use a different card.
    case wrongCardNumber
    
    /// This error is returned when a user scans a card of a [com.tangem.common.extensions.CardType]
    /// that is not specified in [Config.cardFilter].
    case wrongCardType
    
    /// This error is returned when the scanned card doesn't have some essential fields.
    case cardError
    /// This error is returned when the scanned wallet doesn't have some essential fields.
    case walletError
    
    /// This error is returned when SDK fails to perform some low-level crypto algorithm
    case cryptoUtilsError
    
    /// This error is returned when the error occurs inside third-party crypto libraries code
    case failedToGenerateRandomSequence
    
    //MARK: Underlying NFC reader errors
    case readerErrorUnsupportedFeature
    case readerErrorSecurityViolation
    case readerErrorInvalidParameter
    case readerErrorInvalidParameterLength
    case readerErrorParameterOutOfBound
    case readerTransceiveErrorTagConnectionLost
    case readerTransceiveErrorRetryExceeded
    case readerTransceiveErrorTagResponseError
    case readerTransceiveErrorSessionInvalidated
    case readerTransceiveErrorTagNotConnected
    case readerSessionInvalidationErrorSessionTimeout
    case readerSessionInvalidationErrorSessionTerminatedUnexpectedly
    case readerSessionInvalidationErrorFirstNDEFTagRead
    case tagCommandConfigurationErrorInvalidParameters
    case ndefReaderSessionErrorTagNotWritable
    case ndefReaderSessionErrorTagUpdateFailure
    case ndefReaderSessionErrorTagSizeTooSmall
    case ndefReaderSessionErrorZeroLengthMessage
    case readerErrorRadioDisabled
    case readerTransceiveErrorPacketTooLong
	
	// MARK: Files errors
	
	/// Returned when there is no files on card or when successfully read all files
	case fileNotFound
	
	/// Returned when file on card has unwknown file settings
	case notSupportedFileSettings
	
	/// Returned when command setup not available interaction mode (ex. while writing file was setup delete interaction mode)
	case wrongInteractionMode
	
	/// Returned when command  is not met firmware version requirements (ex. for file writing COD must be 3.29 or greater)
	case notSupportedFirmwareVersion
	
	// MARK: Wallet errors
	case maxNumberOfWalletsCreated
	case walletNotFound
	case cardReadWrongWallet
    case cardWithMaxZeroWallets
    case walletCannotBeCreated
        
    public var code: Int {
        switch self {
        // MARK: 1xxxx Errors
        // Errors in NFC Layer, e.g. Tag, connection and tranciesve errors.
        case .tagLost: return 10001
            
        case .unsupportedCommand: return 10003
        case .unsupportedDevice: return 10004
        case .sessionInactive: return 10005
        case .nfcStuck: return 10006
        case .nfcTimeout: return 10007
        case .nfcReaderError: return 10008
        
            
        // MARK: 2xxxx Errors
        // Errors occured during the mapping or parsing data.
        case .serializeCommandError: return 20001
        case .deserializeApduFailed: return 20002
        case .encodingFailedTypeMismatch: return 20003
        case .encodingFailed: return 20004
        case .decodingFailedMissingTag: return 20005
        case .decodingFailedTypeMismatch: return 20006
        case .decodingFailed: return 20007
        case .failedToEncryptApdu: return 20008
        case .failedToDecryptApdu: return 20009
        case .failedToEstablishEncryption: return 20010
        case .invalidResponseApdu: return 20011
            
        // MARK: 3xxxx Errors
        // Errors from card SW codes
        case .unknownStatus: return 30001
        case .errorProcessingCommand: return 30002
        case .invalidState: return 30003
        case .insNotSupported: return 30004
        case .invalidParams: return 30005
        case .needEncryption: return 30006
        case .fileNotFound: return 30007
        case .walletNotFound: return 30008
            
        // MARK: 4yyxx Errors
        // Command Error. Business logical errors that occurred inside commands' implmentation.
        
        case .notPersonalized: return 40001
        case .notActivated: return 40002
        case .walletIsPurged: return 40003
        case .passcodeRequired: return 40004
        case .verificationFailed: return 40005
        case .dataSizeTooLarge: return 40006
        case .missingCounter: return 40007
        case .overwritingDataIsProhibited: return 40008
        case .dataCannotBeWritten: return 40009
        case .missingIssuerPublicKey: return 40010
        case .cardVerificationFailed: return 40011
        case .wrongAccessCode: return 40012
        case .wrongPasscode: return 40013
            
        case .alreadyPersonalized: return 40101
            
        case .cannotBeDepersonalized: return 40201
            
        case .accessCodeRequired: return 40401
        case .cardReadWrongWallet: return 40402
        case .walletCannotBeCreated: return 40403
        case .cardWithMaxZeroWallets: return 40404

        case .alreadyCreated: return 40501
        case .unsupportedCurve: return 40502
        case .maxNumberOfWalletsCreated: return 40503
        case .unsupportedWalletConfig: return 40504
            
        case .purgeWalletProhibited: return 40601
            
        case .accessCodeCannotBeChanged: return 40801
        case .passcodeCannotBeChanged: return 40802
        case .accessCodeCannotBeDefault: return 40803
        
        case .noRemainingSignatures: return 40901
        case .emptyHashes: return 40902
        case .hashSizeMustBeEqual: return 40903
        case .walletIsNotCreated: return 40904
        case .signHashesNotAvailable: return 40905
        case .tooManyHashesInOneTransaction: return 40906
        case .oldCard: return 40907
            
        case .extendedDataSizeTooLarge: return 41101
            
        // MARK: 5xxxx Errors
        // SDK error. Errors, that occurred in the upper level of SDK, like device restrictions, user canceled the operation or SDK is busy and can’t open the new session right now.
        case .unknownError: return 50001
        case .userCancelled: return 50002
        case .busy: return 50003
        case .missingPreflightRead: return 50004
        case .wrongCardNumber: return 50005
        case .wrongCardType: return 50006
        case .cardError: return 50007
        case .notSupportedFirmwareVersion: return 50008
        case .walletError: return 50009
        case .failedToGenerateRandomSequence: return 50010
        case .cryptoUtilsError: return 50011
        case .underlying: return 50012
            
        case .notSupportedFileSettings: return 50017  // TODO: Change to correct code error code
        
        case .wrongInteractionMode: return 50027
            
        // MARK: 9xxxx Errors
        // Reader error.
        
        case .readerErrorUnsupportedFeature: return 90003
        case .readerErrorSecurityViolation: return 90004
        case .readerErrorInvalidParameter: return 90005
        case .readerErrorInvalidParameterLength: return 90006
        case .readerErrorParameterOutOfBound: return 90007
        case .readerTransceiveErrorTagConnectionLost: return 90008
        case .readerTransceiveErrorRetryExceeded: return 90009
        case .readerTransceiveErrorTagResponseError: return 90010
        case .readerTransceiveErrorSessionInvalidated: return 90011
        case .readerTransceiveErrorTagNotConnected: return 90012
        case .readerSessionInvalidationErrorSessionTimeout: return 90013
        case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly: return 90014
        case .readerSessionInvalidationErrorFirstNDEFTagRead: return 90015
        case .tagCommandConfigurationErrorInvalidParameters: return 90016
        case .ndefReaderSessionErrorTagNotWritable: return 90017
        case .ndefReaderSessionErrorTagUpdateFailure: return 90018
        case .ndefReaderSessionErrorTagSizeTooSmall: return 90019
        case .ndefReaderSessionErrorZeroLengthMessage: return 90020
        case .readerErrorRadioDisabled: return 90021
        case .readerTransceiveErrorPacketTooLong: return 90022
            
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .nfcTimeout: return Localization.nfcSessionTimeout
        case .nfcStuck: return Localization.nfcStuckError
        case .alreadyCreated: return "error_already_created".localized
        case .alreadyPersonalized: return "error_already_personalized".localized
        case .busy: return "error_busy".localized
        case .cannotBeDepersonalized: return "error_cannot_be_depersonalized".localized
        case .cardError: return "error_card_error".localized
        case .walletError: return "error_wallet_error".localized
        case .walletIsNotCreated: return "error_wallet_is_not_created".localized
        case .walletIsPurged: return "error_wallet_is_purged".localized
        case .dataCannotBeWritten: return "error_data_cannot_be_written".localized
        case .dataSizeTooLarge: return "error_data_size_too_large".localized
        case .emptyHashes: return "error_empty_hashes".localized
        case .extendedDataSizeTooLarge: return "error_data_size_too_large_extended".localized
        case .hashSizeMustBeEqual: return "error_cannot_be_signed".localized
        case .missingCounter: return "error_missing_counter".localized
        case .missingIssuerPublicKey: return "error_missing_issuer_public_key".localized
        case .noRemainingSignatures: return "error_no_remaining_signatures".localized
        case .notActivated: return "error_not_activated".localized
        case .notPersonalized: return "error_not_personalized".localized
        case .overwritingDataIsProhibited: return "error_data_cannot_be_written".localized
        case .accessCodeCannotBeChanged: return "error_pin1_cannot_be_changed".localized
        case .accessCodeCannotBeDefault: return "error_pin1_cannot_be_default".localized
        case .passcodeCannotBeChanged: return "error_pin2_cannot_be_changed".localized
        case .purgeWalletProhibited: return "error_purge_prohibited".localized
        case .signHashesNotAvailable: return "error_cannot_be_signed".localized
        case .tagLost: return "error_tag_lost".localized
        case .tooManyHashesInOneTransaction: return "error_cannot_be_signed".localized
        case .userCancelled: return "error_user_cancelled".localized
        case .verificationFailed: return "error_verification_failed".localized
        case .cardVerificationFailed: return "error_card_verification_failed".localized
        case .wrongCardNumber: return "error_wrong_card_number".localized
        case .wrongCardType: return "error_wrong_card_type".localized
        case .accessCodeRequired: return "error_pin1_required".localized
        case .passcodeRequired: return "error_pin2_required".localized
        case .underlying(let error): return error.localizedDescription
		case .fileNotFound: return "error_file_not_found".localized
		case .wrongInteractionMode: return "error_wrong_interaction_mode".localized
		case .notSupportedFirmwareVersion: return "error_not_supported_firmware_version".localized
		case .maxNumberOfWalletsCreated: return "error_no_space_for_new_wallet".localized
		case .cardReadWrongWallet: return "error_card_read_wrong_wallet".localized
        case .walletCannotBeCreated: return "Failed to create wallet. AllowSelectBlockchain flag must be set to true"
        case .wrongAccessCode: return "error_wrong_pin1".localized
        case .wrongPasscode: return "error_wrong_pin2".localized
        case .encodingFailed(let message):
            return Localization.genericErrorCode("\(self.code). \(message)")
        case .encodingFailedTypeMismatch(let message):
            return Localization.genericErrorCode("\(self.code). \(message)")
        case .decodingFailed(let message):
            return Localization.genericErrorCode("\(self.code). \(message)")
        case .decodingFailedTypeMismatch(let message):
            return Localization.genericErrorCode("\(self.code). \(message)")
        case .decodingFailedMissingTag(let message):
            return Localization.genericErrorCode("\(self.code). \(message)")
        case .oldCard: return "error_old_card".localized
        default:
            let description = "\(self)".capitalizingFirst()
            return Localization.genericErrorCode("\(self.code). \(description)")
        }
    }
    
    public var jsonDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = (try? encoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }
    
    public var isUserCancelled: Bool {
        if case .userCancelled = self {
            return true
        } else {
            return false
        }
    }
    
    public static func parse(_ error: Error) -> TangemSdkError {
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                return .userCancelled
            case .readerSessionInvalidationErrorSystemIsBusy:
                return .nfcStuck
            case .readerErrorUnsupportedFeature:
                return .readerErrorUnsupportedFeature
            case .readerErrorSecurityViolation:
                return .readerErrorSecurityViolation
            case .readerErrorInvalidParameter:
                return .readerErrorInvalidParameter
            case .readerErrorInvalidParameterLength:
                return .readerErrorInvalidParameterLength
            case .readerErrorParameterOutOfBound:
                return readerErrorParameterOutOfBound
            case .readerTransceiveErrorTagConnectionLost:
                return .readerTransceiveErrorTagConnectionLost
            case .readerTransceiveErrorRetryExceeded:
                return .readerTransceiveErrorRetryExceeded
            case .readerTransceiveErrorTagResponseError:
                return .readerTransceiveErrorTagResponseError
            case .readerTransceiveErrorSessionInvalidated:
                return .readerTransceiveErrorSessionInvalidated
            case .readerTransceiveErrorTagNotConnected:
                return .readerTransceiveErrorTagNotConnected
            case .readerSessionInvalidationErrorSessionTimeout:
                return readerSessionInvalidationErrorSessionTimeout
            case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
                return .readerSessionInvalidationErrorSessionTerminatedUnexpectedly
            case .readerSessionInvalidationErrorFirstNDEFTagRead:
                return .readerSessionInvalidationErrorFirstNDEFTagRead
            case .tagCommandConfigurationErrorInvalidParameters:
                return .tagCommandConfigurationErrorInvalidParameters
            case .ndefReaderSessionErrorTagNotWritable:
                return .ndefReaderSessionErrorTagNotWritable
            case .ndefReaderSessionErrorTagUpdateFailure:
                return .ndefReaderSessionErrorTagUpdateFailure
            case .ndefReaderSessionErrorTagSizeTooSmall:
                return .ndefReaderSessionErrorTagSizeTooSmall
            case .ndefReaderSessionErrorZeroLengthMessage:
                return .ndefReaderSessionErrorZeroLengthMessage
            case .readerErrorRadioDisabled:
                return .readerErrorRadioDisabled
            case .readerTransceiveErrorPacketTooLong:
                return .readerTransceiveErrorPacketTooLong
            @unknown default:
                return .nfcReaderError
            }
        } else {
            return (error as? TangemSdkError) ?? TangemSdkError.underlying(error: error)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var error = [String:String]()
        error["code"] = String(describing: code)
        error["localizedDescription"] = localizedDescription
        var container = encoder.singleValueContainer()
        try container.encode(error)
    }
    
    /// Get error according to the pin type
    /// - Parameters:
    ///   - userCodeType: Specific user code type
    ///   - environment: optional environment. If set, a more specific error will be returned based on previous pin attempts during the session
    /// - Returns: TangemSdkError
    static func from(userCodeType: UserCodeType, environment: SessionEnvironment?) -> TangemSdkError {
        let isCodeSet = environment?.isUserCodeSet(userCodeType) ?? false
        
        switch userCodeType {
        case .accessCode:
            return isCodeSet ? .wrongAccessCode : .accessCodeRequired
        case .passcode:
            return isCodeSet ? .wrongPasscode : .passcodeRequired
        }
    }
}
