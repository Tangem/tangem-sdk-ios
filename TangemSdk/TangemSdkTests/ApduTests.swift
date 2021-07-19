//
//  ApduSerializationTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 12.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CoreNFC
@testable import TangemSdk

@available(iOS 13.0, *)
class ApduTests: XCTestCase {
    func testInitialization() {
        let commandApdu1 = CommandApdu(Instruction.read, tlv: Data())
        let commandApdu2 = CommandApdu(ins: UInt8(0xF2), tlv: Data())
        XCTAssertEqual(commandApdu1, commandApdu2)
        
        
        let cla: UInt8 = 0x00
        let ins: UInt8 = 0x01
        let p1: UInt8 = 0x02
        let p2: UInt8 = 0x03
        let le: Int = -1
        let tlv = [Tlv(.cardId, value: Data([UInt8(0x00), UInt8(0x01), UInt8(0x02), UInt8(0x03)]))]
        let commandApdu3 = CommandApdu(cla: cla, ins: ins, p1: p1, p2: p2, le: le, tlv: tlv.serialize())
        let nfcApdu = NFCISO7816APDU(commandApdu3)
        
        XCTAssertEqual(nfcApdu.instructionClass, cla)
        XCTAssertEqual(nfcApdu.instructionCode, ins)
        XCTAssertEqual(nfcApdu.p1Parameter, p1)
        XCTAssertEqual(nfcApdu.p2Parameter, p2)
        XCTAssertEqual(nfcApdu.expectedResponseLength, le)
        XCTAssertEqual(nfcApdu.data, tlv.serialize())
    }
    
    func testResponse() {
        let badData = Data(hexString: "0001")
        let testData = Data(hexString: "0108FF00000000000111200B534D415254204341534800020102800A312E3238642053444B000341044CB1004B43B407419E29A8FFDB64D4E54B623CEB37F3C2037B3ED6F38EEE0C1F2E5AB5D015DF78FE15EFA5327F59A24C059C999AFC1D3F2A8DDEEE16467CA75F0A027E310C5E8102FFFF820407E2071B830B54414E47454D2053444B00840342544386405D7FFCE7446DAA9084595F383E712A63B2AC4CF7BDE7673F05D6FC629F0D3E0F637910B5A675F66B633331630AEFB614345AF05208DEECF2274FF3B44642AC883041045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26050A736563703235366B3100080400000064070100090205DC604104B45FF0D628E1B59F7AEFA1D5B45AB9D7C47FC090D8B29ACCB515431BDBAD2802DDB3AC5E83A06BD8F13ABB84A465CA3C0FA0B44301F80295A9B4C5E35D5FDFE56204000000646304000000000F01009000")
        let sw1 = UInt8(0x90)
        let sw2 = UInt8(0x00)
        let sw = UInt16(0x9000)
        
        let responseNilApdu = ResponseApdu(badData, sw1, sw2)
        let tlvNilData = responseNilApdu.getTlvData()
        XCTAssertEqual(responseNilApdu.sw, sw)
        XCTAssertEqual(responseNilApdu.statusWord, StatusWord.processCompleted)
        XCTAssertNil(tlvNilData)
        
        let responseUnknownStatusApdu = ResponseApdu(badData, sw1, UInt8(0x69))
        XCTAssertEqual(responseUnknownStatusApdu.sw, UInt16(0x9069))
        XCTAssertEqual(responseUnknownStatusApdu.statusWord, StatusWord.unknown)
        
        let responseApdu = ResponseApdu(testData, sw1, sw2)
        let tlvData = responseApdu.getTlvData()
        XCTAssertNotNil(tlvData)
        XCTAssertTrue(tlvData?.contains(tag: .cardId) ?? false)
    }
}
