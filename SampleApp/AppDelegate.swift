//
//  AppDelegate.swift
//  SampleApp
//
//  Created by Peter Stajger on 17/12/2020.
//

import UIKit
import OnfleetDriver

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let driver = DriverContext.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        #warning("insert app ID here")
        let config = Config(appKey: "{app-id}", appVersion: "1.0", appName: "Sample App")
        driver.initSDK(with: config, environment: .production, app: application, loggers: [OSLogDestination(logSeverity: .warning)])
        return true
    }
}

