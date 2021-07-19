//
//  AppDelegate.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 10/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let model = AppModel()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //Override localizations example
        //Localization.localizationsBundle = Bundle(for: AppDelegate.self)
    
        let window = UIWindow()
        window.rootViewController = UIHostingController(rootView: ContentView()
                                                            .environmentObject(model))
        self.window = window
        window.makeKeyAndVisible()
        return true
    }

}

