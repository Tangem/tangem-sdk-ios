//
//  StringUtilsTest.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class StringUtilsTest: XCTestCase {
    func testRemove() {
        let testString = "This is a test string"
        let newString = "This is a  string"
        XCTAssertEqual(testString.remove("test"), newString)
    }
    
    func testSha256() {
        let testSrting = "test string"
        let testSha = Data(hexString: "d5579c46dfcc7f18207013e65b44e4cb4e2c2298f4ac457ba8f82743f31e930b")
        XCTAssertEqual(testSrting.sha256(), testSha)
    }
    
    func testSha512() {
        let testSrting = "test string"
        let testSha = Data(hexString: "10e6d647af44624442f388c2c14a787ff8b17e6165b83d767ec047768d8cbcb71a1a3226e7cc7816bc79c0427d94a9da688c41a3992c7bf5e4d7cc3e0be5dbac")
        XCTAssertEqual(testSrting.sha512(), testSha)
    }
}
