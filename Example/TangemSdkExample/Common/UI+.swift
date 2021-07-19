//
//  UIButton_.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 02.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    func showActivityIndicator() {
        let views = subviews.filter{ $0 is UIActivityIndicatorView }
        guard views.isEmpty else { return }
        
        isEnabled = false
        
        imageView?.isHidden = true
        imageView?.setNeedsLayout()
        let activityIndicator = createActivityIndicator()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        activityIndicator.color = UIColor.systemBlue
        centerActivityIndicatorInButton(activityIndicator: activityIndicator)
        setTitleColor(UIColor.clear, for: .normal)
        setTitleColor(UIColor.clear, for: .highlighted)
        setTitleColor(UIColor.clear, for: .disabled)
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        let activityArray = subviews.filter{ $0 is UIActivityIndicatorView }
        imageView?.isHidden = false
        imageView?.setNeedsLayout()
        for each in activityArray {
            guard let activity = each as? UIActivityIndicatorView else { continue }
            
            activity.stopAnimating()
            activity.removeFromSuperview()
        }
        isEnabled = true
        setTitleColor(UIColor.systemBlue, for: .normal)
        setTitleColor(UIColor.gray, for: .highlighted)
        setTitleColor(UIColor.lightGray, for: .disabled)
    }
}

extension UIView {
    func createActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.white
        return activityIndicator
    }
    
    func centerActivityIndicatorInButton(activityIndicator : UIActivityIndicatorView) {
        let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
        self.addConstraint(xCenterConstraint)
        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
        self.addConstraint(yCenterConstraint)
    }
    
    func fadeTransition(_ duration: CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction =  CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.type = CATransitionType.fade
        animation.duration = duration
        self.layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
