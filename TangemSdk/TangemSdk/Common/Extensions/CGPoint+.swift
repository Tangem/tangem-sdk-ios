//
//  CGPointCGSize+Ext.swift
//  infoScreenAnim
//
//  Created by Andrew Son on 11/2/20.
//

import CoreGraphics

infix operator +^ : AdditionPrecedence

internal extension CGPoint {
	static func + (left: CGPoint, right: CGPoint) -> CGPoint {
		CGPoint(x: left.x + right.x, y: left.y + right.y)
	}
	
	static func + (left: CGPoint, right: CGSize) -> CGPoint {
		CGPoint(x: left.x + right.width, y: left.y + right.height)
	}
	
	static func + (left: CGPoint, right: CGFloat) -> CGPoint {
		CGPoint(x: left.x + right, y: left.y + right)
	}
	
	static func +^ (left: CGPoint, right: CGFloat) -> CGPoint {
		CGPoint(x: left.x, y: left.y + right)
	}
}

