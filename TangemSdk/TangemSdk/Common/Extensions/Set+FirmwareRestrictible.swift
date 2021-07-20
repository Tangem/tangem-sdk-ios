//
//  Set+FirmwareRestrictible.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/9/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
extension Set where Element: FirmwareRestrictable {
	func minFirmwareVersion() -> FirmwareVersion {
		map { $0.minFirmwareVersion }.max() ?? .min
	}

	func maxFirmwareVersion() -> FirmwareVersion {
		map { $0.maxFirmwareVersion }.min() ?? .min
	}
}
