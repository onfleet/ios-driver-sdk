![Onfleet Driver SDK for iOS](https://user-images.githubusercontent.com/500145/104442724-bdef5980-5595-11eb-90f7-4ddf726a9979.png)

[![CocoaPods Compatible](https://img.shields.io/badge/pod-1.9.3-orange.svg?style=flat)](https://img.shields.io/badge/pod-1.9.3-orange.svg)
[![Swift 5.3](https://img.shields.io/badge/Swift-5.3-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platform iOS](https://img.shields.io/badge/platform-iOS-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-Apache%202-blue.svg?logo=law)](https://github.com/twilio/twilio-verify-ios/blob/main/LICENSE)

## Table of Contents

* [About](#About)
* [Requirements](#Requirements)
* [Documentation](#Documentation)
* [Installation](#Installation)
* [Integration](#Integration)
	* [Initialization](#Initialization)
	* [Push notifications](#PushNotifications)
	* [Background execution](#BackgroundExecution)
	* [Location permissions](#LocationPermissions)
* [Device Verification](#Provision)
* [Sample app](#SampleApp)

<a name='About'></a>

## About

Onfleet Driver SDK allows you to use Onfleet services directly in your iOS app. 
  
<a name='Requirements'></a>

## Requirements
* iOS 13+
* Swift 5
* Xcode 12.5+
* Onfleet application key

<a name='Documentation'></a>

## Documentation

This repository contains auto-generated documentation. See `onfleet-driver-sdk/Docs/index.html`.

<a name='Installation'></a>

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. 

To integrate Onfleet Driver SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'OnfleetDriver', :git => 'https://github.com/onfleet/ios-driver-sdk.git'
```

### Manually

Simply drag and drop `OnfleetDriver.xcframework` into your project and make sure it's linked and embeded with signing into your application's target.

### SPM & Carthage

Unfortunatelly we don't currently support SPM or Carthage, but we will do so in the near future.

<a name='Integration'></a>

## Integration

<a name='Initialization'></a>

### 1. Initialization

Import SDK into the source code where needed

```swift
import OnfleetDriver
```

Onfleet SDK should be initialized at the earliest convenience, ideally in `application(_:didFinishLaunchingWithOptions:)` function. 

For example in your app delegate file:

```swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //initiate SDK
        let config = Config(appKey: "<#app key here#>", appVersion: "<#App version here#>", appName: "<#App name here#>")
        driver.initSDK(with: config, environment: .production(useApnSandbox: true), app: application, loggers: [OSLogDestination(logSeverity: .warning)])
        
        return true
    }

``` 

<a name='PushNotifications'></a>

### 2. Push notifications

When SDK is initialized it automatically registers for remote notifications. Host app is however responsible for managing push notifications and delivering them to the SDK through methods defined in `DriverContext` class. If push notifications will not be forwarded several features will stop working (including [device verification](#Provision)) or will not work as expected.

For example in your app delegate file update code below initialization like this:
 
```swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //initiate SDK
            
        //enable push notification
        UNUserNotificationCenter.current().delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            print("user notification alerts and sound: \(granted ? "granted" : "denied")")
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //forward device token into SDK
        driver.setRemoteNotificationsDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        //forward push notification userInfo into SDK if possible 
        if driver.canHandleRemoteNotification(userInfo: userInfo) {
            driver.handleRemoteNotification(userInfo: userInfo)
        } else {
            // process non-onfleet notifications
        }
    }
    
    // please note that also user notifications (alerts/banners) must be forwarded into SDK from UNUserNotificationCenterDelegate's method
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if driver.canHandleRemoteNotification(userInfo: notification.request.content.userInfo) {
            driver.handleRemoteNotification(notification, completionHandler: completionHandler)
        } else {
            // provide logic for non-onfleet banners
            completionHandler([.alert, .sound])
        }
    }
```

Please refer to Sample app for full integration example.

<a name='BackgroundExecution'></a>

### 3. Background execution

Apps powered by Onfleet SDK require collecting user location while the driver is on duty. Often iOS system kills backgrounded apps due to memory preassure so in case of background termination app must be woken up on the backgorund asap and continue collecting locations. This is achieved by combination of multiple techniques especially `background location updates`, `silent push notifications` and correct `location permissions` granted by user. 

To achieve correct results pls enable in your Xcode project under your app schemes following background mode capabilities:

1. Location Updates
2. Remote Notifications
3. Background Fetch

<a name='LocationPermissions'></a>

### 4. Location permissions

Following location permissions are required:
1. Location -> Allow location access -> **Always**
2. Precise Location -> **On**
This will be referred as _full location permissions_ going forward.

Following privacy description must be set in `Info.plist`
```
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Onfleet only tracks your location when on-duty in order to provide analytics and dispatch work to you.</string>
```

Unfortunatelly, current iOS permissions policy does not open apps in the background if location access is set to **While in Use** or **Once**. This requires apps to ask _full location permissions_. Asking this is sensitive and it is up to SDK integrator to design a flow that is suitable for their users. 

Please follow these rules when implementing your own flow:
1. enforce "Always" no sooner than when going on duty. Don't allow going on duty unless _full location permissions_ are granted. 
2. if driver revokes _full location permissions_ while on duty make sure she goes either off duty or grants _full location permissions_.   

Good practice is to verify permissions before driver attempts to go on duty and present a screen with reasons why these permissions are required. Then app should request access *when in use* or *always*, then guide user to open Settings app and manually select location access **Always**. If precise location is off, similar flow should ask for precise location to be **on**.

Here are reasons why Onfleet requires _full location permissions_:
1. dispatchers can see drivers in real time on web Dashboard
2. delivery recipients can see drivers in real time
3. task delivery ETA is continually recalculated to provide better precisions to recipients
4. locations are used for driver analytics, especially distance driven. Some drivers may be paid by according to this data so precision must be as accurate as possible.
5. SDK never tracks driver's location when off duty
6. system can open suspended application on background so it can continue sending locations to our server

Protocol in `LocationManaging.swift` provides a conveniece wrapper for observing location permissions. Our Sample app contains an example flow.  

Please refer to Sample app for full integration example.

<a name='Provision'></a>

## Device Verification

Due to security reasons each device must be verified. Verification is performed only once and the process is done automatically first time the driver logs in. Please note, that push notifications are used to deliver tokens securely therefore [push notifications must be set up properly](#PushNotifications).

Because of push notifications don't work in iOS simulators we must bypass apn servers and deliver tokens manually. This can be done exclusively on iOS simulators using `provision.sh` script. Please consult the documentation of the script for more details simply by running the script in Terminal.

Please note that bypassing apn servers with the provision script will work only for `test accounts`. These are Onfleet organizations with special flag. The following criteria must be met before an org can be flagged as test account:
- Test drivers must exist in a single organization for which the sdk/application id
above is provisioned.
- If an account is test account and the driver is added
to multiple organizations, the account no longer qualifies as a test account.
- Similarly, if an account is a test account and the driver is removed from that
organization, the account no longer qualifies as a test account.

If you meet the criteria above and you wish to flag your driver account as test
account, please contact Onfleet support at [support@onfleet.com](mailto:support@onfleet.com).

<a name='SampleApp'></a>

## Sample app

This repository contains `Sample App` project that integrates Driver SDK. It provides an overview to core features and guides on how to use them in code. Following features are currently supported:
- Log in, log out, reset password
- Accepting / rejecting invitations
- Setting duty status
- Fetching data
- Tasks list
- Task detail (claiming, starting, completing tasks)

### Set up

1. clone `onfleet/ios-driver-sdk` repository using  `git clone git@github.com:onfleet/ios-driver-sdk.git`
2. open root directory and install pods using `pod install`
3. open `SampleApp.xcworkspace` in Xcode
4. in `AppDelegate.swift` file add your Onfleet **application_id**
5. in target's Signing & Capabilities update bundle identifier and team, please make sure that push notifications work
6. build and run using `SampleApp` scheme
7. when logging in for the first time please perform the [Device Verification](#Provision).
