//
//  ChangeFilesSettingsTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Task for updating settings for files saved on card
@available (iOS 13.0, *)
public final class ChangeFilesSettingsTask: CardSessionRunnable {
	private var changes: [FileSettingsChange]
	
	public init(changes: [FileSettingsChange]) {
		self.changes = changes
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
		changeFileSettings(session: session, completion: completion)
	}
	
	private func changeFileSettings(session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
		guard let changes = changes.popLast() else {
			completion(.success(SuccessResponse(cardId: session.environment.card?.cardId ?? "")))
			return
		}
        let command = ChangeFileSettingsCommand(data: changes)
		command.run(in: session) { (result) in
			switch result {
			case .success:
				self.changeFileSettings(session: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
}
