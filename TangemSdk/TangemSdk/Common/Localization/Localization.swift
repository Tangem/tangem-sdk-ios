//
//  Localizations.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class Localization {
    public static var localizationsBundle: Bundle?
    
    public static let dialogSecurityDelay = string("view_delegate_security_delay")
    public static let unknownCardState = string("nfc_unknown_card_state")
    public static let nfcAlertSignCompleted = string("nfc_alert_sign_completed")
    public static let nfcSessionTimeout = string("nfc_session_timeout")
    public static let nfcAlertDefault = string("nfc_alert_default")
    public static let nfcAlertDefaultDone = string("nfc_alert_default_done")
    public static let nfcStuckError = string("nfc_stuck_error")
    public static let unknownStatus = string("unknownStatus")
   
    static func genericErrorCode(_ code: String) -> String {
        return string("generic_error_code", code)
    }
    
    public static func secondsLeft(_ p1: String) -> String {
        return string("nfc_seconds_left", p1)
    }
    
    public static func readProgress(_ p1: String) -> String {
        return string("reading_data_progress", p1)
    }
    
    public static func writeProgress(_ p1: String) -> String {
        return string("writing_data_progress", p1)
    }
    
    public static func string( _ key: String, _ args: CVarArg...) -> String {
        let format = getFormat(for: key)
        return String(format: format, locale: Locale.current, arguments: args)
    }
    
    public static func getFormat(for key: String) -> String {
        if let overridedBundle = localizationsBundle {
            let format = NSLocalizedString(key,  bundle: overridedBundle, comment: "")
            if format != key {
                return format
            }
        }
        let format = NSLocalizedString(key,  bundle: .sdkBundle, comment: "")
        return format
    }
}
