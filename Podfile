source 'https://github.com/SujiTech/Specs.git'
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
  pod "RxSwiftUtilities", '~> 2.1.0'

  pod 'KeychainAccess', '~> 3.2.0'

  pod 'GRDB.swift', '~> 3.7.0'
  pod 'GRDBCipher', '~> 3.7.0'
  pod 'DeepDiff', '~> 2.0.1'

  pod 'DMSGoPGP', '~> 0.0.17'

  pod 'WordSuggestion', '~> 0.2.1'
  
  pod 'Web3/ContractABI', '~> 0.4.1'
  pod 'Web3/HTTPExtension', '~> 0.4.1'
  pod 'Web3/PromiseKit', '~> 0.4.1'

  pod 'DMS_HDWallet_Cocoa', '~> 0.2.1'
end

def common_ui_pods
  pod 'UITextView+Placeholder', '~> 1.3.1'
  pod "AlignedCollectionViewFlowLayout", '~> 1.1.2'
end

target 'TesserCube' do
  common_pods
  common_ui_pods

  pod 'SwifterSwift', '~> 4.6.0'
  
  # UI
  pod 'SVProgressHUD', :git => 'https://github.com/getaaron/SVProgressHUD.git', :branch => 'dark-mode'
  pod 'IQKeyboardManagerSwift', '~> 6.5.0'
  pod 'Eureka', '~> 4.3.1'
  pod "SearchTextField"
  
  # DEBUG
  pod 'FLEX', '~> 2.4.0', :configurations => ['Debug']

  target 'TesserCubeTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'RxBlocking', '~> 4.0'
  end

  target 'Web3Tests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'TesserCubeKeyboard' do
  common_pods
  pod 'SVProgressHUD', :git => 'https://github.com/getaaron/SVProgressHUD.git', :branch => 'dark-mode'
end

target 'TesserCubeInterpretAction' do
  common_pods
  common_ui_pods
end

target 'TesserCubeComposeAction' do
  common_pods
  common_ui_pods
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
        if config.name == 'XCTest'
            config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'XCTEST'
        end
    end
end
