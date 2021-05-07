![Onfleet Driver SDK for iOS](https://user-images.githubusercontent.com/500145/104442724-bdef5980-5595-11eb-90f7-4ddf726a9979.png)

[![CocoaPods Compatible](https://img.shields.io/badge/pod-1.9.3-orange.svg?style=flat)](https://img.shields.io/badge/pod-1.9.3-orange.svg)
[![Swift 5.3](https://img.shields.io/badge/Swift-5.3-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platform iOS](https://img.shields.io/badge/platform-iOS-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-Apache%202-blue.svg?logo=law)](https://github.com/twilio/twilio-verify-ios/blob/main/LICENSE)

## Table of Contents

* [About](#About)
* [Dependencies](#Dependencies)
* [Requirements](#Requirements)
* [Documentation](#Documentation)
* [Installation](#Installation)
* [Integration](#Integration)
* [Sample app](#SampleApp)

<a name='About'></a>

## About

Onfleet Driver SDK allows you to use Onfleet services directly in your iOS app. Using this SDK 

<a name='Dependencies'></a>

## Dependencies

We currently use several dependencies. Our goal is to remove all of them in future releases of the SDK.

- AFNetworking
- SocketRocket
- UICKeychainStore
- RxSwift
  
<a name='Requirements'></a>

## Requirements
* iOS 12+
* Swift 5.3
* Xcode 11.x

<a name='Documentation'></a>

## Documentation

This repository contains auto-generated documentation. See `/Docs/index.html`.

<a name='Installation'></a>

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate Onfleet Driver SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'OnfleetDriver', :git => 'https://github.com/onfleet/ios-driver-sdk.git'
```

### SPM & Manually

Unfortunatelly we don't currently support SPM or manual integration.

<a name='Integration'></a>

## Integration

Apps powered by Onfleet SDK require collecting user location while the driver is on duty. Often iOS system kills backgrounded apps due to memory preassure so in case of background termination app must be woken up on the backgorund asap and continue collecting locations. This is achieved by combination of multiple techniques especially `background location updates`, `silent push notifications` and correct `location permissions` granted by user. 

### 1. Background execution

To achieve correct results pls enable in your Xcode project under your app schemes following background mode capabilities:
1. Location Updates
2. Remote Notifications

### 2. Location permissions

Following location permissions are required:
1. Location -> Allow location access -> **Always**
2. Precise Location -> **On**

Following privacy description must be set in `Info.plist`
```
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Onfleet only tracks your location when on-duty in order to provide analytics and dispatch work to you.</string>
```

Unfortunatelly, current iOS permissions policy does not wake up apps in the background if location access is set to **While in Use** or **Once**. This requires apps to ask location permission **Always**. Asking this is sensitive and it is up to SDK integrator to design a flow that is suitable for their users. 

Good practice is to verify permissions before driver attempts to go on duty and present a screen with reasons why these permissions are required. Then app should request access *when in use*, then guide user to open Settings app and manually select location access **Always**. If precise location is off, simular flow should ask for precise location to be **on**.

Here are reasons why Onfleet requires these location permissions:
1. dispatchers can see drivers in real time on web Dashboard
2. delivery recipients can see drivers in real time
3. task delivery ETA is continually recalculated to provide better precisions to recipients
4. locations are used for driver analytics, especially distance driven. Some drivers may be paid by according to this data so precision must be as accurate as possible.
5. SDK never tracks driver location when off duty

Protocol in `LocationManaging.swift` provides a conveniece wrapper for observing location permissions.

### Push notifications

When SDK is initialized it automatically registers for remote notifications. Host app is however responsible for managing push notifications and delivering them to the SDK through methods defined in `DriverContext` class. If push notifications will not be forwarded several features will stop working or will not work as expected.

<a name='SampleApp'></a>

## Sample app

This repository contains `Sample App` project that integrates Driver SDK. It provides an overview to core features and guides on how to use them in code. Following features are currently supported:
- Log in, log out, reset password
- Accepting / rejecting invitations
- Setting duty status
- Fetching data and showing list of tasks
- Tasks list
- Task detail (claiming, starting, completing tasks)

### Set up

1. clone `onfleet/ios-driver-sdk` repository using  `git clone git@github.com:onfleet/ios-driver-sdk.git`
2. open root directory and install pods using `pod install`
3. open `SampleApp.xcworkspace` in Xcode
4. build and run using `SampleApp` scheme

