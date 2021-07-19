//
//  DeleteFilesTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Task for deleting files from card.
@available (iOS 13.0, *)
public final class DeleteFilesTask: CardSessionRunnable {
	private var filesToDelete: [Int]?
	
    /// Task for deleting files from card.
    /// - Parameters:
    ///   - filesToDelete: Optional array of indices that should be deleted. If not specified all files will be deleted from card
	public init(filesToDelete: [Int]?) {
		self.filesToDelete = filesToDelete?.sorted(by: <)
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
		guard let filesToDelete = filesToDelete else {
			deleteAllFiles(session: session, completion: completion)
			return
		}
		deleteFiles(indexes: filesToDelete, session: session, completion: completion)
	}
	
	private func deleteAllFiles(session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
		let deleteAllFilesTask = DeleteAllFilesTask()
		deleteAllFilesTask.run(in: session, completion: completion)
	}
	
	private func deleteFiles(indexes: [Int], session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
		var indexesToDelete = indexes
		guard let index = indexesToDelete.popLast() else {
			completion(.success(SuccessResponse(cardId: session.environment.card?.cardId ?? "")))
			return
		}
		let command = DeleteFileCommand(fileAt: index)
		command.run(in: session) { (result) in
			switch result {
			case .success:
				self.deleteFiles(indexes: indexesToDelete, session: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
}
