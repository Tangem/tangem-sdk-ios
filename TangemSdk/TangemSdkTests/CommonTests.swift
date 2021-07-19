//
//  IntUtilsTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class CommonTests: XCTestCase {
    func testAtetstModeCompare() {
        XCTAssertTrue(AttestationTask.Mode.normal < AttestationTask.Mode.full)
        XCTAssertTrue(AttestationTask.Mode.normal <= AttestationTask.Mode.full)
        XCTAssertFalse(AttestationTask.Mode.normal > AttestationTask.Mode.full)
        XCTAssertFalse(AttestationTask.Mode.full < AttestationTask.Mode.normal)
        XCTAssertTrue(AttestationTask.Mode.full >= AttestationTask.Mode.normal)
        XCTAssertTrue(AttestationTask.Mode.full == AttestationTask.Mode.full)
        XCTAssertTrue(AttestationTask.Mode.normal == AttestationTask.Mode.normal)
        XCTAssertFalse(AttestationTask.Mode.full == AttestationTask.Mode.normal)
    }
    
    func testAttestationRawRepresentation() {
        let attestaion = Attestation(cardKeyAttestation: .verifiedOffline,
                                     walletKeysAttestation: .verified,
                                     firmwareAttestation: .skipped,
                                     cardUniquenessAttestation: .failed)
        
        let fromRepresentation = Attestation(rawRepresentaion: attestaion.rawRepresentation)
        XCTAssertNotNil(fromRepresentation)
        XCTAssertEqual(attestaion, fromRepresentation)
    }
}
