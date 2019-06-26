source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

def common_pods
  
  pod 'SwiftLint', '~> 0.30.1'
  pod 'SwiftGen', '~> 6.1.0'

  pod 'DeviceKit', '~> 1.11.0'
  pod 'SnapKit', '~> 4.2.0'
  pod 'DateToolsSwift', '~> 4.0.0'
  pod 'ConsolePrint', '~> 0.1.0'
  pod 'MMWormhole', '~> 2.0.0'

  pod 'RxSwift', '~> 4.4.2'
  pod 'RxCocoa', '~> 4.4.2'

  pod 'DMSOpenPGP', '~> 0.1.2'
  pod 'KeychainAccess', '~> 3.1.2'

  pod 'GRDB.swift', '~> 3.7.0'
  pod 'GRDBCipher', '~> 3.7.0'
  pod 'DeepDiff', '~> 2.0.1'

end

target 'TesserCube' do
  common_pods
  pod 'SwifterSwift', '~> 4.6.0'
  
  # UI
  pod 'SVProgressHUD', '~> 2.2.5'
  pod 'IQKeyboardManagerSwift', '~> 6.2.0'
  pod 'Eureka', '~> 4.3.1'
  pod 'UITextView+Placeholder', '~> 1.2.1'
  pod "AlignedCollectionViewFlowLayout", '~> 1.1.2'

  # DEBUG
  pod 'FLEX', '~> 2.4.0', :configurations => ['Debug', 'Debug Stub', 'Debug PGP']

  target 'TesserCubeTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'RxBlocking', '~> 4.0'
  end

end

target 'TesserCubeKeyboard' do
  common_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            if ['GRDB.swift', 'GRDBCipher'].include? target.name
                config.build_settings['SWIFT_VERSION'] = '4.2'
            end
        end
    end

    installer.pods_project.build_configurations.each do |config|  
        if config.name == 'Debug Stub'
            config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG STUB $(inherited)'
        end
        if config.name == 'Debug PGP'
            config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG DEBUGPGP $(inherited)'
        end
    end
end
