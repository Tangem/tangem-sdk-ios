//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Response from the Tangem card after `CreateWalletCommand`.
@available(iOS 13.0, *)
public struct CreateWalletResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Created wallet
    public let wallet: Card.Wallet
}

/**
 * This command will create a new wallet on the card having ‘Empty’ state.
 * A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
 * App will need to obtain Wallet_PublicKey from the response of `CreateWalletCommand`or `ReadCommand`
 * and then transform it into an address of corresponding blockchain wallet
 * according to a specific blockchain algorithm.
 * WalletPrivateKey is never revealed by the card and will be used by `SignCommand` and `AttestWalletKeyCommand`.
 * RemainingSignature is set to MaxSignatures.
 */
@available(iOS 13.0, *)
public final class CreateWalletCommand: Command {
    var requiresPasscode: Bool { return true }
    
    private let curve: EllipticCurve
    private let isPermanent: Bool
    private let signingMethod = SigningMethod.signHash
    
    private var walletIndex: Int? = nil
    /// Default initializer
    /// - Parameter curve: Elliptic curve of the wallet
    /// - Parameter isPermanent: If true, this wallet cannot be deleted.
    ///   COS before v4: The card will be able to create a wallet according to its personalization only. The value of this parameter can be obtained in this way:
    ///   `card.settings.mask.contains(.permanentWallet)`
    public init(curve: EllipticCurve, isPermanent: Bool) {
        self.curve = curve
        self.isPermanent = isPermanent
    }
    
    deinit {
        Log.debug("CreateWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion >= .multiwalletAvailable,
           !card.settings.isSelectBlockchainAllowed {
            return .walletCannotBeCreated
        }
        
        guard card.supportedCurves.contains(curve) else {
            return TangemSdkError.unsupportedCurve
        }
        
        if card.firmwareVersion < FirmwareVersion.multiwalletAvailable {
            if isPermanent != card.settings.isPermanentWallet {
                return TangemSdkError.unsupportedWalletConfig
            }
            
            if let cardSigningMethods = card.settings.defaultSigningMethods,
                !signingMethod.isSubset(of: cardSigningMethods) {
                return TangemSdkError.unsupportedWalletConfig
            }
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let maxIndex = card.settings.maxWalletsCount
        let occupiedIndexes = card.wallets.map { $0.index }
        let allIndexes = 0..<maxIndex
        if let firstAvailableIndex = allIndexes.filter({ !occupiedIndexes.contains($0) }).sorted().first {
            self.walletIndex = firstAvailableIndex
        } else {
            //already created for old cards mostly
            completion(.failure(maxIndex == 1 ? .alreadyCreated : .maxNumberOfWalletsCreated))
            return
        }
        
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                var wallets: [Card.Wallet] = session.environment.card?.wallets ?? []
                wallets.append(response.wallet)
                session.environment.card?.wallets = wallets.sorted(by: { $0.index < $1.index })
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            guard let card = card else { return error }
            
            if card.firmwareVersion >= .isPasscodeStatusAvailable,
               let isPasscodeSet = card.isPasscodeSet, !isPasscodeSet {
                return .alreadyCreated
            }
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.walletIndex, value: walletIndex)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        let maskBuilder = MaskBuilder<WalletSettingsMask>()
        maskBuilder.add(.isReusable)
        if isPermanent {
            maskBuilder.add(.isPermanent)
        }
        
        if environment.card?.firmwareVersion >= .multiwalletAvailable {
            try tlvBuilder.append(.settingsMask, value: maskBuilder.build())
            try tlvBuilder.append(.curveId, value: curve)
            try tlvBuilder.append(.signingMethod, value: signingMethod)
        }
        
        return CommandApdu(.createWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CreateWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        let index = try decoder.decode(.walletIndex) ?? walletIndex!
        
        let wallet = Card.Wallet(publicKey: try decoder.decode(.walletPublicKey),
                                 curve: curve,
                                 settings: Card.Wallet.Settings(isPermanent: isPermanent),
                                 totalSignedHashes: 0,
                                 remainingSignatures: environment.card?.remainingSignatures,
                                 index: index)
        
        return CreateWalletResponse(cardId: try decoder.decode(.cardId), wallet: wallet)
    }
}
