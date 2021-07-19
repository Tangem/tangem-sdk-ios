//
//  WriteFilesTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Response for `WriteFilesTask`.
/// - Parameters:
///   - cardId: CID, Unique Tangem card ID number
///   - fileIndices: Indicies of created files
@available (iOS 13.0, *)
public struct WriteFilesResponse: JSONStringConvertible {
	public let cardId: String
	public let filesIndices: [Int]
}

/// This task allows to write multiple files to a card.
/// There are two secure ways to write files.
/// 1. Data can be signed by Issuer (the one specified on card during personalization) - `FileDataProtectedBySignature`.
/// 2. Data can be protected by Passcode (PIN2). `FileDataProtectedByPasscode` In this case,  Passcode (PIN2) is required for the command.
@available (iOS 13.0, *)
public final class WriteFilesTask: CardSessionRunnable {
	private let files: [DataToWrite]
    private let overwriteAllFiles: Bool
		
	private var currentFileIndex: Int = 0
	private var savedFilesIndices: [Int] = []
	
    public init(files: [DataToWrite], overwriteAllFiles: Bool = false) {
		self.files = files
        self.overwriteAllFiles = overwriteAllFiles
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
		guard files.count > 0 else {
			completion(.success(WriteFilesResponse(cardId: "", filesIndices: [])))
			return
		}
		if overwriteAllFiles {
			deleteFiles(session: session, completion: completion)
			return
		}
		writeFile(session: session, completion: completion)
	}
	
	private func deleteFiles(session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
		let task = DeleteFilesTask(filesToDelete: nil)
		task.run(in: session) { (result) in
			switch result {
			case .success:
				self.writeFile(session: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func writeFile(session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
		guard let card = session.environment.card else {
			completion(.failure(.cardError))
			return
		}
        
		guard currentFileIndex < files.count else {
			completion(.success(.init(cardId: card.cardId, filesIndices: savedFilesIndices)))
			return
		}
		WriteFileCommand(dataToWrite: files[currentFileIndex])
			.run(in: session) { (result) in
				switch result {
				case .success(let response):
					self.currentFileIndex += 1
					self.savedFilesIndices.append(response.fileIndex ?? 0)
					self.writeFile(session: session, completion: completion)
				case .failure(let error):
					completion(.failure(error))
				}
			}
	}
	
}
