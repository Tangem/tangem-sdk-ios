//
//  CAAnimations+.swift
//  TangemSdk
//
//  Created by Andrew Son on 11/3/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

internal extension CAKeyframeAnimation {
	convenience init(keyPath: String, values: [Any], keyTimes: [NSNumber], reversed: Bool, fillMode: CAMediaTimingFillMode = .forwards, isRemovedOnCompletion: Bool = false, repeatCount: Float = 1, autoreverses: Bool = false, duration: Double? = nil, delay: Double = 0, shouldDelayAffectDuration: Bool = false) {
		
		self.init(keyPath: keyPath)
		let targetValues = reversed ? values.reversed() : values
		self.values = targetValues
		self.keyTimes = keyTimes
		self.fillMode = fillMode
		self.isRemovedOnCompletion = isRemovedOnCompletion
		self.repeatCount = repeatCount
		self.autoreverses = autoreverses
		
		if let d = duration {
			self.duration = d
			self.duration += shouldDelayAffectDuration ? delay : 0
		}
		
		self.beginTime = delay
	}
}

internal extension CALayer {
	func sublayer(with name: String) -> CALayer? {
		guard
			let sublayers = sublayers,
			let targetLayer = sublayers.first(where: { $0.name == name })
		else { return nil }
		
		return targetLayer
	}
}
