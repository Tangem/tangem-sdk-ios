//
//  ContentView.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 04.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @State private var isOpenHealthTest = false
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                
                ScrollView {
                    Text(model.logText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .font(.caption)
                }
                .clipped()
                .frame(width: geo.size.width)
                .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 2)
                            .padding(.horizontal, 8))
                
                ScrollView {
                    VStack(spacing: 4) {
                        HStack {
                            Button("Clear", action: model.clear)
                            Button("Copy", action: model.copy)
                        }
                        
                        Picker("Select method", selection: $model.method) {
                            ForEach(0..<AppModel.Method.allCases.count) { index in
                                Text(AppModel.Method.allCases[index].rawValue)
                                    .tag(AppModel.Method.allCases[index])
                            }
                        }
                        
                        Button("Start") { model.start() }
                            .buttonStyle(ExampleButton(isLoading: model.isScanning))
                            .frame(width: 100)
                            .padding()
                        
                        additionalView
                    }
                    .padding(.horizontal, 20)
                    .frame(width: geo.size.width)
                }
            }
        }
        .actionSheet(isPresented: $model.showWalletSelection) {
            let walletButtons: [Alert.Button] = model.card?.wallets.map { wallet in
                let publicKey = wallet.publicKey.hexString
                let formattedKey = "\(publicKey.prefix(6))...\(publicKey.suffix(6)) (\(wallet.curve.rawValue))"
                
                return ActionSheet.Button.default(Text(formattedKey)) {
                    model.start(walletPublicKey: wallet.publicKey)
                }
            } ?? []
            
            let cancelButton = ActionSheet.Button.cancel {
                model.isScanning = false
            }
            
            return ActionSheet(title: Text("Select wallet"),
                               message: nil,
                               buttons: walletButtons + [cancelButton])
        }
    }
    
    @ViewBuilder
    var additionalView: some View {
        switch model.method {
        case .attest:
            VStack {
                Text("Attestation configuration")
                    .font(.headline)
                    .bold()
                
                Picker("", selection: $model.attestationMode) {
                    ForEach(0..<AttestationTask.Mode.allCases.count) { index in
                        Text(AttestationTask.Mode.allCases[index].rawValue)
                            .tag(AttestationTask.Mode.allCases[index])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
        case .createWallet:
            VStack {
                Text("Create wallet configuration")
                    .font(.headline)
                    .bold()
                
                Toggle("Is permanent wallet", isOn: $model.isPermanent)
                
                if let supportedCurves = model.card?.supportedCurves {
                    Picker("", selection: $model.curve) {
                        ForEach(0..<supportedCurves.count) { index in
                            Text(supportedCurves[index].rawValue)
                                .tag(supportedCurves[index])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
        default:
            EmptyView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var model = AppModel()
    
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 8")
            .environmentObject(model)
    }
}
