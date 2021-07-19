//
//  NFCReader.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CoreNFC
import UIKit

/// Provides NFC communication between an application and Tangem card.
@available(iOS 13.0, *)
final class NFCReader: NSObject {
    private(set) var tag = CurrentValueSubject<NFCTagType?, TangemSdkError>(nil)
    private(set) var isSessionReady = CurrentValueSubject<Bool, Never>(false)
    
    /// Session paused indicator for pins UI
    
    var isPaused = false
    
    /// Current connected tag
    private var connectedTag: NFCTag? = nil
    /// Active nfc session
    private var readerSession: NFCTagReaderSession?
    
    /// Session cancellation flag
    @Published private var cancelled: Bool = false
    
    /// Session invalidation flag
    @Published private var invalidatedWithError: TangemSdkError? = nil
    
    /// Session cancellation publisher. Transforms cancellation to error
    private var cancellationPublisher: AnyPublisher<Void, TangemSdkError> {
        $cancelled
            .tryMap { cancelled -> Void in
                if cancelled {
                    throw TangemSdkError.userCancelled
                } else {
                    return ()
                }
            }
            .mapError { $0.toTangemSdkError() }
            .eraseToAnyPublisher()
    }
    /// Session restart polling publisher
    private var restartPollingPublisher: CurrentValueSubject<Void, Never> = .init(())
    
    /// Workaround for session timeout error (60 sec)
    private var sessionTimerCancellable: AnyCancellable? = nil
    
    /// Workaround for tag timeout connection error (20 sec)
    private var tagTimerCancellable: AnyCancellable? = nil
    
    /// Workaround for nfc stuck
    private var nfcStuckTimerCancellable: AnyCancellable? = nil
    
    // Idle timer
    private var idleTimerCancellable: AnyCancellable? = nil
    
    /// Keep alert message for restore after pause
    private var _alertMessage: String? = nil
    
    //Store session live subscriptions
    private var bag = Set<AnyCancellable>()
    private var sessionConnectCancellable: AnyCancellable? = nil
    
    private var sendRetryCount = Constants.retryCount
    private var startRetryCount = Constants.startRetryCount
    private let pollingOption: NFCTagReaderSession.PollingOption
    private var sessionDidBecomeActiveTimestamp: Date = .init()
    
    init(pollingOption: NFCTagReaderSession.PollingOption = [.iso14443]) {
        self.pollingOption = pollingOption
    }
    
    deinit {
        Log.debug("Reader deinit")
    }
    
    private var queue: DispatchQueue? = nil
}

//MARK: CardReader
@available(iOS 13.0, *)
extension NFCReader: CardReader {
    var alertMessage: String {
        get { return _alertMessage ?? "" }
        set {
            readerSession?.alertMessage = newValue
            _alertMessage = newValue
        }
    }
    
    /// Start session and try to connect with tag
    func startSession(with message: String?) {
        Log.nfc("Start NFC session")
        queue = DispatchQueue(label: "tangem_sdk_reader_queue")
        bag = Set<AnyCancellable>()
        isPaused = false
        invalidatedWithError = nil
        cancelled = false
        connectedTag = nil
        
        let alertMessage = message ?? Localization.nfcAlertDefault
        _alertMessage = alertMessage
        
        let isExistingSessionActive = readerSession?.isReady ?? false
        if !isExistingSessionActive {
            startNFCStuckTimer()
            start()
        }
        
        NotificationCenter //For instant cancellation
            .default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .map { _ in return true }
            .filter{[unowned self] _ in
                let distanceToSessionActive = self.sessionDidBecomeActiveTimestamp.distance(to: Date())
                if !self.isSessionReady.value || distanceToSessionActive < 1 {
                    Log.nfc("Filter out сancelled event")
                    return false
                }
                return true
            }
            .assign (to: \.cancelled, on: self)
            .store(in: &bag)

        $cancelled //speed up cancellation if no tag interaction
            .dropFirst()
            .filter { $0 }
            .filter {[unowned self] _ in self.idleTimerCancellable == nil }
            .sink {[unowned self] _ in
                Log.nfc("Cancelled event received")
                self.invalidatedWithError = .userCancelled
            }
            .store(in: &bag)
        
        $invalidatedWithError //speed up cancellation if no tag interaction
            .dropFirst()
            .compactMap { $0 }
            .filter {[unowned self] _ in self.isSessionReady.value }
            .sink {[unowned self] error in
                Log.nfc("Invalidated event received")
                if !self.isPaused { //skip completion event for paused session.
                    //Actually we need this stuff for immediate cancel(or error) handling only,
                    //before the session detect any tags or if restart polling in action
                    self.tag.send(completion: .failure(error))
                    self.tag = .init(nil)
                } else {
                    self.tag.send(nil)
                }
                
                isSessionReady.send(false)
            }
            .store(in: &bag)
        
        isSessionReady //Handle session state
            .dropFirst()
            .removeDuplicates()
            .sink {[unowned self] isReady in
                Log.nfc("NFC session is active: \(isReady)")
                if isReady {
                    self.nfcStuckTimerCancellable = nil
                    self.startSessionTimer()
                } else { //clenup resources
                    self.stopTimers()
                }
            }
            .store(in: &bag)
        
        //handle tag events
        tag
            .dropFirst()
            .sink { _ in  }
                receiveValue: {[unowned self] tag in
                    Log.nfc("Received tag: \(String(describing: tag))")
                    if tag != nil {
                        self.startTagTimer()
                        if case .tag = tag {
                            self.startIdleTimer()
                        }
                    } else {
                        self.tagTimerCancellable = nil
                        self.idleTimerCancellable = nil
                        connectedTag = nil
                    }
                }
            .store(in: &bag)
        
        restartPollingPublisher //handle restart polling events
            .dropFirst()
            .sink {[unowned self] _ in
                guard let session = self.readerSession,
                      session.isReady else {
                    return
                }
                
                Log.nfc("Restart polling invoked")
                self.tag.send(nil)
                session.restartPolling()
            }
            .store(in: &bag)
    }
    
    func resumeSession() {
        Log.nfc("Resume reader session invoked")
        isPaused = false
        startSession(with: _alertMessage)
    }
    
    func pauseSession(with errorMessage: String? = nil) {
        Log.nfc("Pause reader session invoked")
        isPaused = true
        stopSession(with: errorMessage)
    }
    
    func stopSession(with errorMessage: String? = nil) {
        Log.nfc("Stop reader session invoked")
        stopTimers()
        if let errorMessage = errorMessage {
            readerSession?.invalidate(errorMessage: errorMessage)
        } else {
            readerSession?.invalidate()
        }
    }
    
    func restartPolling() {
        restartPollingPublisher.send(())
    }
    
    /// Send apdu command to connected tag
    /// - Parameter apdu: serialized apdu
    /// - Parameter completion: result with ResponseApdu or NFCError otherwise
    func sendPublisher(apdu: CommandApdu) -> AnyPublisher<ResponseApdu, TangemSdkError> {
        Log.nfc("Send publisher invoked")
        idleTimerCancellable = nil
        
        guard case let .iso7816(tag) = connectedTag else {
            return Fail(error: TangemSdkError.unsupportedCommand).eraseToAnyPublisher()
        }
        
        let requestTimestamp = Date()
        Log.apdu(apdu)
        return tag
            .sendCommandPublisher(cApdu: apdu)
            .combineLatest(cancellationPublisher)
            .map{ rapdu, _ -> ResponseApdu in
                return rapdu
            }
            .tryCatch{[weak self] error -> AnyPublisher<ResponseApdu, TangemSdkError> in
                guard let self = self else {
                    return Empty(completeImmediately: true).eraseToAnyPublisher()
                }
                
                if case .userCancelled = error {
                    throw error
                }
                
                let distance = requestTimestamp.distance(to: Date())
                if distance > Constants.timestampTolerance || self.sendRetryCount <= 0 { //retry to fix old device issues
                    Log.nfc("Invoke restart polling on error")
                    self.restartPolling()
                    return Empty(completeImmediately: false).eraseToAnyPublisher()
                } else {
                    self.sendRetryCount -= 1
                    Log.nfc("Retry send. distance: \(distance)")
                    return self.sendPublisher(apdu: apdu)
                }
            }
            .handleEvents (receiveOutput: {[weak self] rApdu in
                guard let self = self else { return }
                Log.nfc("Success response from card received")
                Log.apdu(rApdu)
                self.sendRetryCount = Constants.retryCount
                self.startIdleTimer()
            })
            .mapError { $0.toTangemSdkError() }
            .eraseToAnyPublisher()
    }
    
    private func start() {
        readerSession?.invalidate() //Important! We must keep invalidate/begin in balance after start retries
        readerSession = NFCTagReaderSession(pollingOption: self.pollingOption, delegate: self, queue: queue)!
        readerSession!.alertMessage = _alertMessage!
        readerSession!.begin()
    }
    
    //MARK: Timers
    private func startNFCStuckTimer() {
        startRetryCount = Constants.startRetryCount
        nfcStuckTimerCancellable = Timer
            .TimerPublisher(interval: Constants.nfcStuckTimeout, runLoop: RunLoop.main, mode: .common)
            .autoconnect()
            .sink {[unowned self] _ in
                Log.nfc("Stop by stuck timer")
                startRetryCount -= 1
                if startRetryCount == 0 {
                    self.stopSession(with: TangemSdkError.nfcStuck.localizedDescription)
                    self.invalidatedWithError = .nfcStuck
                    self.nfcStuckTimerCancellable = nil
                } else {
                    self.start()
                }
            }
    }
    
    private func startTagTimer() {
        tagTimerCancellable = Timer
            .TimerPublisher(interval: Constants.tagTimeout, tolerance: 0, runLoop: RunLoop.main, mode: .common)
            .autoconnect()
            .receive(on: queue!)
            .filter {[unowned self] _ in self.idleTimerCancellable != nil }
            .sink {[unowned self] _ in
                Log.nfc("Stop by tag timer")
                self.stopSession(with: Localization.nfcSessionTimeout)
                self.tagTimerCancellable = nil
            }
    }
    
    private func startSessionTimer() {
        sessionTimerCancellable = Timer
            .TimerPublisher(interval: Constants.sessionTimeout, runLoop: RunLoop.main, mode: .common)
            .autoconnect()
            .receive(on: queue!)
            .sink {[unowned self] _ in
                Log.nfc("Stop by session timer")
                self.stopSession(with: Localization.nfcSessionTimeout)
                self.sessionTimerCancellable = nil
            }
    }
    
    private func startIdleTimer() {
        idleTimerCancellable = Timer
            .TimerPublisher(interval: Constants.idleTimeout, runLoop: RunLoop.main, mode: .common)
            .autoconnect()
            .receive(on: queue!)
            .sink {[unowned self] _ in
                Log.nfc("Restart by idle timer")
                self.restartPolling()
                self.idleTimerCancellable = nil
            }
    }
    
    private func stopTimers() {
        nfcStuckTimerCancellable = nil
        sessionTimerCancellable = nil
        tagTimerCancellable = nil
        idleTimerCancellable = nil
    }
}

//MARK: NFCTagReaderSessionDelegate
@available(iOS 13.0, *)
extension NFCReader: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        sessionDidBecomeActiveTimestamp = Date()
        isSessionReady.send(true)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Log.nfc("NFC Session did invalidate with: \(error.localizedDescription)")
        if nfcStuckTimerCancellable == nil { //handle stuck retries ios14
            invalidatedWithError = TangemSdkError.parse(error as! NFCReaderError)
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Log.nfc("NFC tag detected: \(tags)")
        let nfcTag = tags.first!
        
        sessionConnectCancellable = session.connectPublisher(tag: nfcTag)
            .sink {[weak self] completion in
                switch completion {
                case .failure(_):
                    self?.restartPolling()
                case .finished:
                    break
                }
                self?.sessionConnectCancellable = nil
            } receiveValue: {[weak self] _ in
                guard let self = self else { return }
                
                self.connectedTag = nfcTag
                self.tag.send(nfcTag.tagType)
            }
    }
}

//MARK: Constants
@available(iOS 13.0, *)
extension NFCReader {
    enum Constants {
        static let tagTimeout = 20.0
        static let idleTimeout = 2.0
        static let sessionTimeout = 60.0
        static let nfcStuckTimeout = 1.0
        static let retryCount = 10
        static let startRetryCount = 10
        static let timestampTolerance = 1.0
    }
}
