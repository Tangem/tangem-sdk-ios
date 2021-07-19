//
//  ButtonStyles.swift
//  round21
//
//  Created by Alexander Osokin on 06.05.2021.
//

import Foundation
import SwiftUI

struct ExampleButton: ButtonStyle {
    var isDisabled: Bool = false
    var isLoading: Bool = false
    var bgColor: Color = .orange
    var fgColor: Color = .white
    var height: CGFloat = 50
    
    @ViewBuilder private var loadingOverlay: some View {
        if isLoading  {
            ZStack {
                bgColor
                ActivityIndicatorView()
            }
        } else {
            Color.clear
        }
    }
    
    @ViewBuilder private var disabledOverlay: some View {
        if isDisabled  {
            Color.white.opacity(0.4)
        } else {
            Color.clear
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .foregroundColor(fgColor)
            Spacer()
        }
        .frame(height: height)
        .padding(.horizontal, 10)
        .font(.system(size: 17))
        .foregroundColor(Color.white)
        .background(bgColor)
        .overlay(loadingOverlay)
        .overlay(disabledOverlay)
        .cornerRadius(40)
        .allowsHitTesting(!isDisabled && !isLoading)
    }
}
