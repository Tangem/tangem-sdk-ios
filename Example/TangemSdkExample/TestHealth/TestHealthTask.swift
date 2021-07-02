//
//  TestHealthTask.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 23.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk


class TestHealthTask: CardSessionRunnable {
    public var onStep: (() -> Void)? = nil
    
    private var runsCounter: Int = 0
    private let maxRuns: Int = 50
    private var currentWalletPublicKey: Data? = nil
    
    deinit {
        print("TestHealthTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        self.createWallet(in: session, completion: completion)
    }
    
    func createWallet(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        print("createWallet")
        CreateWalletCommand(curve: .secp256k1, isPermanent: false).run(in: session) { result in
            switch result {
            case .success(let response):
                self.currentWalletPublicKey = response.wallet.publicKey
            case .failure(let error):
                completion(.failure(error))
                return
            }
            self.sign(in: session, completion: completion)
        }
    }
    
    func sign(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        print("sign")
        let hash = try! CryptoUtils.generateRandomBytes(count: 32)
        SignHashCommand(hash: hash, walletPublicKey: self.currentWalletPublicKey!).run(in: session)  { result in
            if case let .failure(error) = result {
                completion(.failure(error))
                return
            }
            self.purgeWallet(in: session, completion: completion)
        }
    }
    
    func purgeWallet(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        print("purge")
        PurgeWalletCommand(publicKey: self.currentWalletPublicKey!).run(in: session)  { result in
            if case let .failure(error) = result {
                completion(.failure(error))
                return
            }
            
            self.finishStep(in: session, completion: completion)
        }
    }
    
    func finishStep(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        runsCounter += 1
        onStep?()
        
        if runsCounter == maxRuns {
            runsCounter = 0
            session.pause()
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                session.resume()
                self.createWallet(in: session, completion: completion)
            }
        } else {
            DispatchQueue.global().async {
                self.createWallet(in: session, completion: completion)
            }
        }
    }
}