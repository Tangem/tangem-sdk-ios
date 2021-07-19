//
//  PinViewController.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

enum PinViewControllerState {
    case pin1
    case pin2
}

@available(iOS 13.0, *)
class PinViewController: UIViewController, UITextFieldDelegate {
    
    var completionHandler: (String?) -> Void
    let state: PinViewControllerState
    let cardId: String?
    
    @IBOutlet weak var lblTitle: UILabel! {
        didSet {
            switch state {
            case .pin1: lblTitle.text = String(format: "pin_enter".localized, "pin1".localized)
            case .pin2: lblTitle.text = String(format: "pin_enter".localized, "pin2".localized)
            }
        }
    }
    @IBOutlet weak var btnContinueBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnSecureEntry: UIButton!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var pinText: UITextField! {
        didSet {
            pinText.delegate = self
            switch state {
            case .pin1: pinText.placeholder = "pin1".localized
            case .pin2: pinText.placeholder = "pin2".localized
            }
        }
    }
    @IBOutlet weak var btnContinue: UIButton! {
        didSet {
            btnContinue.isEnabled = false
            btnContinue.setTitle("common_continue".localized, for: .normal)
        }
    }
    
    @IBOutlet weak var lblCard: UILabel!
    
    init?(coder: NSCoder, state: PinViewControllerState, cardId: String? = nil, completionHandler: @escaping (String?) -> Void) {
        self.completionHandler = completionHandler
        self.state = state
        self.cardId = cardId
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lblCard.text = cardId
        pinText.becomeFirstResponder()
    }
    
    @IBAction func btnActionTapped(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.completionHandler(nil)
        }
    }
    
    @IBAction func btnContinueTapped(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.completionHandler(self.pinText.text?.trim())
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
    
    @IBAction func btnSecureEntryTapped(_ sender: UIButton) {
        btnSecureEntry.isSelected.toggle()
        pinText.isSecureTextEntry.toggle()
    }
    
    @IBAction func textFieldChanged(_ sender: UITextField) {
        btnContinue.isEnabled = !(sender.text?.isEmpty ?? true)
    }
}
