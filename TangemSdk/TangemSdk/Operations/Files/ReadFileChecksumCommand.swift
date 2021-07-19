//
//  ReadFileChecksumCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response for `ReadFileChecksumCommand`
@available (iOS 13.0, *)
public struct ReadFileChecksumResponse: JSONStringConvertible {
	public let cardId: String
	public let checksum: Data
	public let fileIndex: Int?
}

/// The command that prompts the card to create a file checksum. This checksum is used to check the integrity of the file on the card
@available (iOS 13.0, *)
public final class ReadFileChecksumCommand: Command {
	public var requiresPasscode: Bool { readPrivateFiles }
	
	private let fileIndex: Int
	private let readPrivateFiles: Bool
	
	public init(fileIndex: Int, readPrivateFiles: Bool) {
		self.fileIndex = fileIndex
		self.readPrivateFiles = readPrivateFiles
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<ReadFileChecksumResponse>) {
		readFileData(session: session, completion: completion)
	}
	
	func performPreCheck(_ card: Card) -> TangemSdkError? {
		if card.firmwareVersion < .filesAvailable {
			return .notSupportedFirmwareVersion
		}
		
		return nil
	}
	
	private func readFileData(session: CardSession, completion: @escaping CompletionResult<ReadFileChecksumResponse>) {
		transceive(in: session) { (result) in
			switch result {
			case .success(let response):
				completion(.success(response))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
		var tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
			.append(.pin, value: environment.accessCode.value)
			.append(.cardId, value: environment.card?.cardId)
			.append(.fileIndex, value: fileIndex)
			.append(.interactionMode, value: FileDataMode.readFileHash)
		if readPrivateFiles {
			tlvBuilder = try tlvBuilder.append(.pin2, value: environment.passcode.value)
		}
		return CommandApdu(.readFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadFileChecksumResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = TlvDecoder(tlv: tlv)
		return ReadFileChecksumResponse(cardId: try decoder.decode(.cardId),
										checksum: try decoder.decode(.codeHash),
										fileIndex: try decoder.decode(.fileIndex))
	}
}
