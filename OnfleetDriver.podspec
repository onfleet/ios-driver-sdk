Pod::Spec.new do |s|
  s.name = "OnfleetDriver"
  s.version = "0.43"
  s.summary = "Onfleet Driver SDK"
  s.homepage = "https://github.com/onfleet/ios-driver-sdk"
  s.license = {
    :type => 'Copyright',
    :text => <<-LICENSE
    Onfleet Driver SDK
    Created by Onfleet on  01/05/2021
    Copyright (c) 2022 Onfleet. All rights reserved.
    LICENSE
  }
  s.author = 'Onfleet, Inc.'
  s.platform = :ios, '16.0'
  s.requires_arc = true
  s.swift_version = '5.3'
  s.cocoapods_version = '>= 1.10.1'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '$(inherited) arm64' }
  # OnfleetDriver.xcframework statically links Objective-C components that rely on
  # runtime class/category registration, so the integrating app target must link
  # with -ObjC to force-load those symbols; otherwise the app can hit
  # missing-selector / unregistered-class crashes at runtime.
  #
  # OnfleetDriver re-exports OnfleetReactiveKit, whose module ships as a satellite
  # .swiftinterface inside OnfleetDriver.framework/Modules. Swift does not search a
  # framework's Modules dir for non-primary modules on its own, so add it to the
  # import path; without this, `import OnfleetDriver` fails to resolve OnfleetReactiveKit.
  # The framework lands at different paths depending on integration: CocoaPods/Xcode
  # extract the xcframework slice under XCFrameworkIntermediates/, while a directly
  # embedded framework sits at $(BUILT_PRODUCTS_DIR). Include both; only one exists per
  # build and unused -I paths are harmless. Every setting prepends $(inherited) so it
  # augments — never replaces — the integrating target's own flags.
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '$(inherited) arm64',
    'OTHER_LDFLAGS' => '$(inherited) -ObjC',
    'SWIFT_INCLUDE_PATHS' => '$(inherited) "$(BUILT_PRODUCTS_DIR)/XCFrameworkIntermediates/OnfleetDriver/OnfleetDriver.framework/Modules" "$(BUILT_PRODUCTS_DIR)/OnfleetDriver.framework/Modules"'
  }
  s.source = { :git => 'https://github.com/onfleet/ios-driver-sdk.git' }
  s.vendored_frameworks = 'OnfleetDriver.xcframework'
  s.preserve_paths = 'OnfleetDriver.xcframework'
end
