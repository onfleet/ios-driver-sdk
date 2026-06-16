import ProjectDescription

// Tuist manifest for the published OnfleetDriver SDK's SampleApp. deploy-sdk.sh copies
// this to the destination repo root and runs `tuist generate`, so the published repo
// ships a ready-to-open SampleApp.xcodeproj (+ Derived/) without integrators needing
// Tuist — they only run `pod install`.
//
// OnfleetDriver is NOT a dependency here: CocoaPods provides it (see the generated
// Podfile, `pod 'OnfleetDriver', :path => '.'`), vendoring the local
// OnfleetDriver.xcframework and supplying the linker/import settings (-ObjC and the
// OnfleetReactiveKit satellite SWIFT_INCLUDE_PATHS) via the podspec. Keeping the
// framework wiring in CocoaPods is what lets this manifest stay free of hardcoded
// framework-search / import paths.
let project = Project(
    name: "SampleApp",
    targets: [
        .target(
            name: "SampleApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.onfleet.driver.sampleApp",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "SampleApp/Info.plist"),
            sources: ["SampleApp/**/*.swift"],
            resources: [
                "SampleApp/**/*.storyboard",
                "SampleApp/**/*.xcassets",
            ],
            entitlements: .file(path: "SampleApp/SampleApp.entitlements"),
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "5.0",
                    "TARGETED_DEVICE_FAMILY": "1,2",
                ]
            )
        ),
    ]
)
