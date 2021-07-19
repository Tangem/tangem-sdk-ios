//
//  FileWriteSettings.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Settings that will be used while writing files on card
@available (iOS 13.0, *)
public enum FileWriteSettings: Hashable, FirmwareRestictible {
	case none, verifiedWithPasscode
	
	public var minFirmwareVersion: FirmwareVersion {
		switch self {
		case .none: return FirmwareVersion(major: 3, minor: 29)
		case .verifiedWithPasscode: return FirmwareVersion(major: 3, minor: 34)
		}
	}
	
	public var maxFirmwareVersion: FirmwareVersion {
		switch self {
		case .none, .verifiedWithPasscode: return .max
		}
	}
}
