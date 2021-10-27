platform :ios, '12.0' 

inhibit_all_warnings! 

use_frameworks! 

target 'SampleApp' do 
  pod 'OnfleetDriver', :path => '.' 
  pod 'RxCocoa'

  puts "********** PODS POST INSTALLATION HOOK **********"
  post_install do |pi|
      pi.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        end
      end
  end
end