//
//  UtilsTest.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 31.10.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//
import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class DataExtensionTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSha256() {
        let testData = Data(repeating: UInt8(5), count: 64)
        let shaCryptoKit =  testData.getSha256()
        XCTAssertEqual(shaCryptoKit, Data(hexString: "B1BCCCF15ED0A0BD63635AE686AF9F75E522AB057C928E39F65EE83048D72C75"))
    }
    
    func testSha512() {
        let testData = Data(repeating: UInt8(5), count: 64)
        let shaCryptoKit =  testData.getSha512()
        XCTAssertEqual(shaCryptoKit, Data(hexString: "856079398BE994391989EA610BA54AEDA815948C9C6F06B2728D46871D666841EBBC9179CD6DA2E8D86CE746E63D260C81DEB3AF51E0A790E1DF5B72597F85C6"))
    }
    
    func testSha256CryptoKitPerfomance() {
        let testData = try! CryptoUtils.generateRandomBytes(count: 256)
        measure {
            _ = testData.getSha256()
        }
    }
    
    func testBytesConversion() {
        let testData = Data(repeating: UInt8(2), count: 3)
        let testArray = Array.init(repeating: UInt8(2), count: 3)
        XCTAssertEqual(testData.toBytes, testArray)
    }
    
    func testToDateString() {
        let testData = Data(hexString: "07E2071B")
        let testDate = "Jul 27, 2018"
        XCTAssertEqual(testDate, testData.toDate()?.toString())
        
        let testData1 = Data(hexString: "07E2071B1E")
        let testDate1 = "Jul 27, 2018"
        XCTAssertEqual(testDate1, testData1.toDate()?.toString())
        
        XCTAssertNil(Data(hexString: "07E207").toDate())
    }
    
    func testFromHexConversion() {
        let testData = Data([UInt8(0x07),UInt8(0xE2),UInt8(0x07),UInt8(0x1B)])
        XCTAssertEqual(testData, Data(hexString: "07E2071B"))
    }
    
    func testToHexConversion() {
        let testData = Data([UInt8(0x07),UInt8(0xE2),UInt8(0x07),UInt8(0x1B)])
        let hex = testData.hexString
        XCTAssertEqual(hex, "07E2071B")
    }
    
    func testToUtf8Conversion() {
        let testData = Data(hexString: "736563703235366B3100")
        let testString = "secp256k1"
        let converted = testData.utf8String
        XCTAssertNotNil(converted)
        XCTAssertEqual(converted!, testString)
    }
    
    func testToIntConversion() {
        let testData = Data(hexString: "00026A03")
        let intData = 158211
        let converted = testData.toInt()
        XCTAssertEqual(converted, intData)
    }
}
