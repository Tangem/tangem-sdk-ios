//
//  DeleteFileCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Command that deletes file at specified index
@available (iOS 13.0, *)
public final class DeleteFileCommand: Command {
    var requiresPasscode: Bool { return true }
    
	private let fileIndex: Int
	
	public init(fileAt index: Int) {
		fileIndex = index
	}
	
	func performPreCheck(_ card: Card) -> TangemSdkError? {
		if card.firmwareVersion < .filesAvailable {
			return .notSupportedFirmwareVersion
		}
		
		return nil
	}
	
	func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
		let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
			.append(.cardId, value: environment.card?.cardId)
			.append(.pin, value: environment.accessCode.value)
			.append(.pin2, value: environment.passcode.value)
			.append(.interactionMode, value: FileDataMode.deleteFile)
			.append(.fileIndex, value: fileIndex)
		return CommandApdu(.writeFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = TlvDecoder(tlv: tlv)
		return SuccessResponse(cardId: try decoder.decode(.cardId))
	}
}
