//
//  JSONRPCTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 21.05.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class JSONRPCTests: XCTestCase {
    var testCard: Card {
        let json = readFile(name: "Card")
        let data = json.data(using: .utf8)
        XCTAssertNotNil(data)
        return try! JSONDecoder.tangemSdkDecoder.decode(Card.self, from: data!)
    }
    
    func testJsonRPCRequestParse() {
        let json = "{\"jsonrpc\": \"2.0\", \"method\": \"subtract\", \"params\": {\"subtrahend\": 23, \"minuend\": 42}, \"id\": 3}"
        
        let request = try? JSONRPCRequest(jsonString: json)
        XCTAssertNotNil(request)
        XCTAssertEqual(request!.method, "subtract")
        XCTAssertEqual(request!.params["subtrahend"] as! Int, Int(23))
    }
    
    func testInitialMessageInit() {
        let json = "{\"header\": \"Some header\", \"body\": \"Some body\"}"
        
        if let message = Message(json) {
            XCTAssertEqual(message.header, "Some header")
            XCTAssertEqual(message.body, "Some body")
        } else {
            XCTAssertNotNil(nil)
        }
    }
    
    func testJsonResponse() {
        let response = SuccessResponse(cardId: "c000111122223333")
        let result: Result<SuccessResponse, TangemSdkError> = .success(response)
        let jsonResponse = result.toJsonResponse(id: 1).json
        let testResponse =
            """
            {
              "jsonrpc" : "2.0",
              "result" : {
                "cardId" : "c000111122223333"
              },
              "id" : 1
            }
            """
        XCTAssertEqual(jsonResponse, testResponse)
    }
    
    func testDecodeSingleHex() {
        var dict: [String: Any] = .init()
        dict["pubKey"] = "AABBCCDDEEFF"
        let data: Data = try! dict.value(for: "pubKey")
        XCTAssert(data == Data(hexString: "AABBCCDDEEFF"))
    }
    
    func testDecodeMultipleHex() {
        var dict: [String: Any] = .init()
        dict["hashes"] = ["AABBCCDDEEFF", "AABBCCDDEEFFGG"]
        let data: [Data] = try! dict.value(for: "hashes")
        XCTAssert(data[0] == Data(hexString: "AABBCCDDEEFF"))
        XCTAssert(data[1] == Data(hexString: "AABBCCDDEEFFGG"))
    }
    
    func testScan() {
        testMethod(name: "Scan", result: testCard)
    }
    
    func testCreateWallet() {
        let result = CreateWalletResponse(cardId: "c000111122223333",
                                          wallet: Card.Wallet(publicKey: Data(hexString: "5130869115a2ff91959774c99d4dc2873f0c41af3e0bb23d027ab16d39de1348"),
                                                              curve: .secp256r1,
                                                              settings: Card.Wallet.Settings(isPermanent: true),
                                                              totalSignedHashes: 10,
                                                              remainingSignatures: 100,
                                                              index: 1))
        testMethod(name: "CreateWallet", result: result)
    }
    
    func testPurgeWallet() {
        let result = PurgeWalletCommand.Response(cardId: "c000111122223333")
        testMethod(name: "PurgeWallet", result: result)
    }
    
    func testDepersonalize() {
        let result = DepersonalizeResponse(success: true)
        testMethod(name: "Depersonalize", result: result)
    }
    
    func testPersonalize() {
        testPersonalizeConfig(name: "v4")
        testPersonalizeConfig(name: "v3.05ada")
    }
    
    func testSetPin1() {
        let result = SuccessResponse(cardId: "c000111122223333")
        
        testMethod(name: "SetAccessCode", result: result)
    }
    
    func testSetPin2() {
        let result = SuccessResponse(cardId: "c000111122223333")
        
        testMethod(name: "SetPasscode", result: result)
    }
    
    func testPreflightRead() {
        testMethod(name: "PreflightRead", result: testCard)
    }
    
    func testSignHashes() {
        let result = SignHashesResponse(cardId: "c000111122223333",
                                        signatures: [Data(hexString: "eb7411c2b7d871c06dad51e58e44746583ad134f4e214e4899f2fc84802232a1"),
                                                     Data(hexString: "33443bd93f350b62a90a0c23d30c6d4e9bb164606e809ccace60cf0e2591e58c")],
                                        totalSignedHashes: 2)
        
        testMethod(name: "SignHashes", result: result)
    }
    
    func testSignHash() {
        let result = SignHashResponse(cardId: "c000111122223333",
                                      signature: Data(hexString: "eb7411c2b7d871c06dad51e58e44746583ad134f4e214e4899f2fc84802232a1"),
                                      totalSignedHashes: 2)
        
        testMethod(name: "SignHash", result: result)
    }
    
    func testMethodNotFound() {
        let json = "{\"jsonrpc\": \"2.0\", \"method\": \"sign_task\", \"params\": {\"walletIndex\": \"AABBCCDDEEFFGGHHKKLLMMNN\", \"hashes\": [\"AABBCCDDEEFF\", \"AABBCCDDEEFFGG\"]}, \"id\": 1}"
        let request = try? JSONRPCRequest(jsonString: json)
        XCTAssertNotNil(request)
        do {
            _ = try JSONRPCConverter.shared.convert(request: request!)
            XCTAssertTrue(false)
        } catch {
            let jsError = error as? JSONRPCError
            XCTAssertNotNil(jsError)
            XCTAssertTrue(jsError!.code == JSONRPCError.Code.methodNotFound.rawValue)
        }
    }
    
    private func testPersonalizeConfig(name: String) {
        guard let testData = getTestData(for: name) else {
            XCTAssert(false, "Failed to create test data \(name)")
            return
        }
        
        //test request
        do {
           let request = try JSONRPCRequest(jsonString: testData.request)
            //test convert request
            XCTAssertNoThrow(try JSONRPCConverter.shared.convert(request: request))
        } catch {
            XCTAssert(false, "Failed to create request for \(name)")
            return
        }
    }
    
    private func testMethod<TResult: Encodable>(name: String, result: TResult) {
        guard let testData = getTestData(for: name) else {
            XCTAssert(false, "Failed to create test data \(name)")
            return
        }
        
        //test request
        do {
           let request = try JSONRPCRequest(jsonString: testData.request)
            //test convert request
            XCTAssertNoThrow(try JSONRPCConverter.shared.convert(request: request))
        } catch {
            XCTAssert(false, "Failed to create request for \(name)")
            return
        }
        
        //test response
        guard let responseJson = try? JSONSerialization.jsonObject(with: testData.response, options: []) as? [String: Any],
              let resultValue = responseJson["result"],
              let resultJsonData = try? JSONSerialization.data(withJSONObject: resultValue, options: .sortedKeys),
              let resultData = try? JSONEncoder.tangemSdkTestEncoder.encode(result)
        else {
            XCTAssert(false, "Failed to parse test response for \(name)")
            return
        }
      
        XCTAssertEqual(resultData.utf8String!.lowercased(), resultJsonData.utf8String!.lowercased())
    }
    
    private func getTestData(for method: String) -> (request: String, response: Data)? {
        let fileText = readFile(name: method)
        let jsonData = fileText.data(using: .utf8)!
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                  let request = json["request"] else {
                XCTAssert(false, "Failed to parse test json \(name)")
                return nil
            }
            
            let requestData = try JSONSerialization.data(withJSONObject: request, options: .prettyPrinted)
            
            let responseData: Data
            if let response = json["response"] {
                responseData = try JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
            } else {
                let cardResponse = "{\"result\": \(testCard.json)}"
                responseData = cardResponse.data(using: .utf8)!
            }

            guard let requestValue = String(data: requestData, encoding: .utf8) else {
                XCTAssert(false, "Failed to parse test json \(name)")
                return nil
            }
            
            return (requestValue, responseData)
        } catch {
            print(error)
            XCTAssert(false, "Failed to parse test json \(name)")
            return nil
        }
    }
    
    private func readFile(name: String) -> String {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: name, ofType: "json")!
        return try! String(contentsOfFile: path)
    }
}
