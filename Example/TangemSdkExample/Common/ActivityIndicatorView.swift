//
//  ActivityIndicatorView.swift
//  round21
//
//  Created by Alexander Osokin on 06.05.2021.
//

import Foundation
import SwiftUI

struct IndicatorSettings {
    let style: UIActivityIndicatorView.Style
    let color: UIColor
    
    static let `default` = IndicatorSettings(style: .medium, color: .white)
}

struct ActivityIndicatorView: UIViewRepresentable {
    var isAnimating: Bool
    var style: UIActivityIndicatorView.Style
    var color: UIColor
    
    init(isAnimating: Bool = true, style: UIActivityIndicatorView.Style = .medium, color: UIColor = .white) {
        self.isAnimating = isAnimating
        self.style = style
        self.color = color
    }
    
    init(settings: IndicatorSettings) {
        self.isAnimating = true
        self.style = settings.style
        self.color = settings.color
    }
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicatorView>) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: style)
        indicator.color = color
        return indicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicatorView>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
