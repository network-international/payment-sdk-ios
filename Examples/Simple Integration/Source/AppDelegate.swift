//
//  AppDelegate.swift
//  Simple Integration
//
//  Created by Johnny Peter on 08/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import UIKit
import NISdk

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let firstScreen = StoreFrontViewController();
        let navigationController = UINavigationController(rootViewController: firstScreen)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }

    // BenefitPay returns its result to the app over the callBackTag URL scheme; forward it to NISdk.
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return NISdk.sharedInstance.handleBenefitInAppCallback(url: url)
    }
}
