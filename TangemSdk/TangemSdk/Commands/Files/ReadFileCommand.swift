//
//  ReadFileCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response for `ReadFileCommand`
@available (iOS 13.0, *)
public struct ReadFileResponse: JSONStringConvertible {
	public let cardId: String
	public let size: Int?
	public let fileData: Data
	public let fileIndex: Int
	public let fileSettings: FileSettings
	public let fileDataSignature: Data?
	public let fileDataCounter: Int?
}

/// Command that read single file at specified index. Reading private file will prompt user to input a passcode.
@available (iOS 13.0, *)
public final class ReadFileCommand: Command {
	public typealias CommandResponse = ReadFileResponse
	
	public var requiresPin2: Bool { readPrivateFiles }
	
	private let fileIndex: Int
	private let readPrivateFiles: Bool
	
	private var fileData: Data = Data()
	private var offset: Int = 0
	private var dataSize: Int = 0
	private var fileSettings: FileSettings? = nil
	
	public init(fileIndex: Int, readPrivateFiles: Bool) {
		self.fileIndex = fileIndex
		self.readPrivateFiles = readPrivateFiles
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<ReadFileResponse>) {
		readFileData(session: session, completion: completion)
	}
	
	func performPreCheck(_ card: Card) -> TangemSdkError? {
		if card.firmwareVersion < FirmwareConstraints.AvailabilityVersions.files {
			return .notSupportedFirmwareVersion
		}
		
		if card.status == CardStatus.notPersonalized {
			return .notPersonalized
		}
		
		return nil
	}
	
	func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
		if requiresPin2, case TangemSdkError.invalidParams = error {
			return .pin2OrCvcRequired
		}
		return error
	}
	
	private func readFileData(session: CardSession, completion: @escaping CompletionResult<ReadFileResponse>) {
		transieve(in: session) { (result) in
			switch result {
			case .success(let response):
				if let size = response.size {
					if size == 0 {
						completion(.success(response))
						return
					}
					self.dataSize = size
					self.fileSettings = response.fileSettings
				}
				self.fileData += response.fileData
				guard self.fileData.count < self.dataSize else {
					self.completeTask(response, completion: completion)
					return
				}
				self.offset = self.fileData.count
				self.readFileData(session: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func completeTask(_ data: ReadFileResponse, completion: @escaping CompletionResult<ReadFileResponse>) {
		let response = ReadFileResponse(cardId: data.cardId,
											size: dataSize,
											fileData: fileData,
											fileIndex: data.fileIndex,
											fileSettings: fileSettings ?? data.fileSettings,
											fileDataSignature: data.fileDataSignature,
											fileDataCounter: data.fileDataCounter)
		completion(.success(response))
	}
	
	func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
		let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
			.append(.pin, value: environment.pin1.value)
			.append(.cardId, value: environment.card?.cardId)
			.append(.fileIndex, value: fileIndex)
			.append(.offset, value: offset)
		if readPrivateFiles {
			try tlvBuilder.append(.pin2, value: environment.pin2.value)
		}
		return CommandApdu(.readFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadFileResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = TlvDecoder(tlv: tlv)
		return ReadFileResponse(cardId: try decoder.decode(.cardId),
									size: try decoder.decodeOptional(.size),
									fileData: try decoder.decodeOptional(.issuerData) ?? Data(),
									fileIndex: try decoder.decodeOptional(.fileIndex) ?? 0,
									fileSettings: try decoder.decodeOptional(.fileSettings) ?? .public,
									fileDataSignature: try decoder.decodeOptional(.issuerDataSignature),
									fileDataCounter: try decoder.decodeOptional(.issuerDataCounter))
	}
}
