Pod::Spec.new do |s|
  s.name         = "OnfleetDriver"
  s.version      = "0.9.1"
  s.summary      = "Onfleet Driver SDK #{s.version.to_s}"
  s.homepage     = "https://docs.onfleet.com/"
  s.license      = {
    :type => 'Copyright',
    :text => <<-LICENSE
    Onfleet SDK
    Created by Onfleet on  01/05/2021
    Copyright (c) 2021 Onfleet. All rights reserved.
    LICENSE
  }
  s.author       = 'Onfleet, Inc.'
  s.platform     = :ios, '11.0'
  s.requires_arc = true
  s.swift_version = '5.3'
  s.cocoapods_version = '>= 1.9.3'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.source = { :git => "https://github.com/onfleet/ios-driver-sdk.git" }
  s.vendored_frameworks = 'OnfleetDriver.xcframework'
  s.preserve_paths = 'OnfleetDriver.xcframework' #, 'OnfleetDriver.dSYMs/*.dSYM'
  s.dependency 'AFNetworking'
  s.dependency 'SocketRocket'
  s.dependency 'UICKeyChainStore', '~> 2.2.1'
  s.dependency 'RxSwift', '~> 5.1.1'
  s.dependency 'RxCocoa', '~> 5.1.1'
end
