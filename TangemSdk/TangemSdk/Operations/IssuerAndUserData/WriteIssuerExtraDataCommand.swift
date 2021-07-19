//
//  WriteIssuerExtraDataCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
/**
 * This command writes Issuer Extra Data field and its issuer’s signature.
 * Issuer Extra Data is never changed or parsed from within the Tangem COS.
 * The issuer defines purpose of use, format and payload of Issuer Data.
 * For example, this field may contain a photo or biometric information for ID card products.
 */
@available(*, deprecated, message: "Use files instead") //todo: text
@available(iOS 13.0, *)
public final class WriteIssuerExtraDataCommand: Command {
    private static let singleWriteSize = 900
    private static let maxSize = 32 * 1024
    
    private var mode: IssuerExtraDataMode = .readOrStartWrite
    private var offset: Int = 0
    private let issuerData: Data
    private var issuerPublicKey: Data?
    private let startingSignature: Data
    private let finalizingSignature: Data
    private let issuerDataCounter: Int?
    
    private var completion: CompletionResult<SuccessResponse>?
    private var viewDelegate: SessionViewDelegate?
    
    /// Initializer
    /// - Parameters:
    ///   - issuerData: Data provided by issuer
    ///   - issuerPublicKey: Optional key for check data validity. If nil, `issuerPublicKey` from current card will be used
    ///   - startingSignature:  Issuer’s signature with Issuer Data Private Key of `cardId`, `issuerDataCounter` (if flags Protect_Issuer_Data_Against_Replay and
    ///    Restrict_Overwrite_Issuer_Extra_Data are set in `SettingsMask`) and size of `issuerData`.
    ///   - finalizingSignature: Issuer’s signature with Issuer Data Private Key of `cardId`, `issuerData` and `issuerDataCounter` (the latter one only if flags Protect_Issuer_Data_Against_Replay
    ///   and Restrict_Overwrite_Issuer_Extra_Data are set in `SettingsMask`).
    ///   - issuerDataCounter: An optional counter that protect issuer data against replay attack.
    public init(issuerData: Data, issuerPublicKey: Data? = nil, startingSignature: Data, finalizingSignature: Data, issuerDataCounter: Int? = nil) {
        self.issuerData = issuerData
        self.issuerPublicKey = issuerPublicKey
        self.startingSignature = startingSignature
        self.finalizingSignature = finalizingSignature
        self.issuerDataCounter = issuerDataCounter
    }
    
    deinit {
        Log.debug("WriteIssuerExtraDataCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if issuerPublicKey == nil {
            issuerPublicKey = card.issuer.publicKey
        }
        
        if issuerData.count > WriteIssuerExtraDataCommand.maxSize {
            return .extendedDataSizeTooLarge
        }
        
        if card.settings.isIssuerDataProtectedAgainstReplay
            && issuerDataCounter == nil {
            return .missingCounter
        }
		
		if card.firmwareVersion >= .filesAvailable {
			return .notSupportedFirmwareVersion
		}
        
        if !verify(with: card.cardId) {
            return .verificationFailed
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        self.completion = completion
        self.viewDelegate = session.viewDelegate
        writeData(session)
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if card?.settings.isIssuerDataProtectedAgainstReplay ?? false {
            if case .invalidParams = error {
                return .dataCannotBeWritten
            }
            
            if case .invalidState = error {
                return .overwritingDataIsProhibited
            }
        }
        return error
    }
    
    private func writeData(_ session: CardSession) {
        showProgress()
        transceive(in: session) {result in
            switch result {
            case .success(let response):
                switch self.mode {
                case .readOrStartWrite:
                    self.mode = .writePart
                    self.writeData(session)
                case .writePart:
                    self.offset += WriteIssuerExtraDataCommand.singleWriteSize
                    if self.offset >= self.issuerData.count {
                        self.mode = .finalizeWrite
                    }
                    self.writeData(session)
                case .finalizeWrite:
                    self.viewDelegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                    self.completion?(.success(response))
                }
            case .failure(let error):
                self.completion?(.failure(error))
            }
        }
    }
    
    private func calculateChunk() -> Range<Int> {
        let bytesLeft = issuerData.count - offset
        let to = min(bytesLeft, WriteIssuerExtraDataCommand.singleWriteSize)
        return offset..<offset + to
    }
    
    private func verify(with cardId: String) -> Bool {
        let startingVerifierResult = IssuerDataVerifier.verify(cardId: cardId,
                                                               issuerDataSize: issuerData.count,
                                                               issuerDataCounter: issuerDataCounter,
                                                               publicKey: issuerPublicKey!,
                                                               signature: startingSignature)
        
        let finalizingVerifierResult = IssuerDataVerifier.verify(cardId: cardId,
                                                                 issuerData: issuerData,
                                                                 issuerDataCounter: issuerDataCounter,
                                                                 publicKey: issuerPublicKey!,
                                                                 signature: finalizingSignature)
        
        return startingVerifierResult && finalizingVerifierResult
    }
    
    private func showProgress() {
        guard mode == .writePart else {
            return
        }
        let progress = Int(round(Float(offset)/Float(issuerData.count) * 100.0))
        viewDelegate?.showAlertMessage(Localization.writeProgress(String(describing: progress)))
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.interactionMode, value: mode)
        
        switch mode {
        case .readOrStartWrite:
            try tlvBuilder
                .append(.size, value: issuerData.count)
                .append(.issuerDataSignature, value: startingSignature)
            
            if let counter = issuerDataCounter {
                try tlvBuilder.append(.issuerDataCounter, value: counter)
            }
            
        case .writePart:
            try tlvBuilder
                .append(.issuerData, value: issuerData[calculateChunk()])
                .append(.offset, value: offset)
            
        case .finalizeWrite:
            try tlvBuilder.append(.issuerDataSignature, value: finalizingSignature)
        }
        
        return CommandApdu(.writeIssuerData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
