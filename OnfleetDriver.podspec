Pod::Spec.new do |s|
  s.name = "OnfleetDriver"
  s.version = "0.16"
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
  s.platform = :ios, '13.0'
  s.requires_arc = true
  s.swift_version = '5.3'
  s.cocoapods_version = '>= 1.10.1'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.source = { :git => 'https://github.com/onfleet/ios-driver-sdk.git' }
  s.vendored_frameworks = 'OnfleetDriver.xcframework'
  s.preserve_paths = 'OnfleetDriver.xcframework'
end
