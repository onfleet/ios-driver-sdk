//
//  AppDelegate.swift
//  SampleApp
//
//  Created by Peter Stajger on 17/12/2020.
//

import UIKit
import UserNotifications

import OnfleetDriver

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let driver = DriverContext.shared
    let center: UNUserNotificationCenter = .current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #error("insert your application_id here")
        let applicationId = "YOUR_APP_ID_HERE"
        let logLevel = ONLogLevel.warning
        let environment = Environment.production
        
        let config = Config(appKey: applicationId, appVersion: "1.0", appName: "Sample App")
        driver.initSDK(with: config, environment: environment, app: application, loggers: [OSLogDestination(logSeverity: logLevel)])
        
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            print("user notification alerts and sound: \(granted ? "granted" : "denied")")
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        driver.setRemoteNotificationsDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if driver.canHandleRemoteNotification(userInfo: userInfo) {
            driver.handleRemoteNotification(userInfo: userInfo)
        } else {
            // process non-onfleet notifications
        }
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if driver.canHandleRemoteNotification(userInfo: notification.request.content.userInfo) {
            driver.handleRemoteNotification(notification, completionHandler: completionHandler)
        } else {
            // provide logic for non-onfleet banners
            completionHandler([.alert, .sound])
        }
    }
}
