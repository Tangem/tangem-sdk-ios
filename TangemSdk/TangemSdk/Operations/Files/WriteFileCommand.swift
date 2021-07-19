//
//  WriteFileCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response for `WriteFileCommand`
@available (iOS 13.0, *)
public struct WriteFileResponse: JSONStringConvertible {
	public let cardId: String
	public let fileIndex: Int?
}

/// Command for writing file on card
@available (iOS 13.0, *)
public final class WriteFileCommand: Command {
	public var requiresPasscode: Bool { dataToWrite.requiredPasscode }
	
	private static let singleWriteSize = 900
	private static let maxSize = 48 * 1024
	
	private let dataToWrite: DataToWrite
	
	private var mode: FileDataMode = .initiateWritingFile
	private var offset: Int = 0
	private var fileIndex: Int = 0
	
	public init(dataToWrite: DataToWrite) {
		self.dataToWrite = dataToWrite
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFileResponse>) {
		writeFileData(session: session, completion: completion)
	}
	
	func performPreCheck(_ card: Card) -> TangemSdkError? {
		if card.firmwareVersion < .filesAvailable,
			card.firmwareVersion < dataToWrite.minFirmwareVersion {
			return .notSupportedFirmwareVersion
		}
		
		if dataToWrite.data.count > WriteFileCommand.maxSize {
			return .dataSizeTooLarge
		}
		if let dataToWrite = dataToWrite as? FileDataProtectedBySignature {
			if !isCounterValid(issuerDataCounter: dataToWrite.counter, card: card) {
				return .missingCounter
			}
			guard let publicKey = dataToWrite.issuerPublicKey else {
				return .missingIssuerPublicKey
			}
            guard verifySignatures(publicKey: publicKey, cardId: card.cardId) else {
				return .verificationFailed
			}
		}
		
		return nil
	}
	
	func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        guard let card = card else { return error }
        
		if case .invalidParams = error, isCounterRequired(card: card) {
			return .dataCannotBeWritten
		}
		
        if case .invalidState = error, card.settings.isIssuerDataProtectedAgainstReplay {
			return .overwritingDataIsProhibited
		}
        
		return error
	}
	
	func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
		let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
			.append(.cardId, value: environment.card?.cardId)
			.append(.pin, value: environment.accessCode.value)
			.append(.interactionMode, value: mode)
		switch mode {
		case .initiateWritingFile:
			try dataToWrite.addStartingTlvData(tlvBuilder, withEnvironment: environment)
				.append(.size, value: dataToWrite.data.count)
		case .writeFile:
			try tlvBuilder.append(.issuerData, value: getDataToWrite())
				.append(.offset, value: offset)
				.append(.fileIndex, value: fileIndex)
		case .confirmWritingFile:
			try dataToWrite.addFinalizingTlvData(tlvBuilder, withEnvironment: environment)
				.append(.fileIndex, value: fileIndex)
		default:
			break
		}
		
		return CommandApdu(.writeFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> WriteFileResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = TlvDecoder(tlv: tlv)
		return WriteFileResponse(cardId: try decoder.decode(.cardId),
									 fileIndex: try decoder.decode(.fileIndex))
	}
	
	// MARK: Private functions
	
	private func writeFileData(session: CardSession, completion: @escaping CompletionResult<WriteFileResponse>) {
		// TODO: Insert view delegate method to display progress to user
		transceive(in: session) { (result) in
			switch result {
			case .success(let response):
				switch self.mode {
				case .initiateWritingFile:
					self.fileIndex = response.fileIndex ?? 0
					self.mode = .writeFile
					self.writeFileData(session: session, completion: completion)
				case .writeFile:
					self.offset += WriteFileCommand.singleWriteSize
					if self.offset >= self.dataToWrite.data.count {
						self.mode = .confirmWritingFile
					}
					self.writeFileData(session: session, completion: completion)
				case .confirmWritingFile:
					completion(.success(WriteFileResponse(cardId: response.cardId, fileIndex: self.fileIndex)))
				default:
					completion(.failure(.wrongInteractionMode))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func getDataToWrite() -> Data {
		dataToWrite.data[offset..<offset+calculatePartSize()]
	}
	
	private func calculatePartSize() -> Int {
		let bytesLeft = dataToWrite.data.count - offset
		return min(WriteFileCommand.singleWriteSize, bytesLeft)
	}
	
	private func isCounterValid(issuerDataCounter: Int?, card: Card) -> Bool {
		isCounterRequired(card: card) ?
			issuerDataCounter != nil :
			true
	}
	
	private func isCounterRequired(card: Card) -> Bool {
		if dataToWrite.requiredPasscode { return false }
        return card.settings.isIssuerDataProtectedAgainstReplay
	}
	
	private func verifySignatures(publicKey: Data, cardId: String) -> Bool {
		guard let dataToWrite = dataToWrite as? FileDataProtectedBySignature else {
			return true
		}
		let startingSignatureIsValid = IssuerDataVerifier.verify(cardId: cardId,
																 issuerDataSize: dataToWrite.data.count,
																 issuerDataCounter: dataToWrite.counter,
																 publicKey: publicKey,
																 signature: dataToWrite.startingSignature)
		let finalizingSignatureIsValid = IssuerDataVerifier.verify(cardId: cardId,
																   issuerData: dataToWrite.data,
																   issuerDataCounter: dataToWrite.counter,
																   publicKey: publicKey,
																   signature: dataToWrite.finalizingSignature)
		return startingSignatureIsValid && finalizingSignatureIsValid
	}
	
}
