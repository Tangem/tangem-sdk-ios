//
//  Track.swift
//  TangemSdk
//
//  Created by Andrew Son on 24/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class Track {
    private let logger: TangemSdkLogger?
    private var startTime: DispatchTime?
    
    init(logger: TangemSdkLogger? = nil) {
        self.logger = logger
    }
    
    public func start() {
        startTime = .now()
    }
    
    @discardableResult
    public func stop() -> Double {
        guard let startTime = startTime else {
            return 0
        }
        
        let millisec = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
        logger?.log("Elapsed time in milliseconds: \(millisec)", level: .debug)
        return millisec
    }
}
