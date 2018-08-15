Pod::Spec.new do |s|
  s.name              = "ProcedureKit"
  s.version           = "5.0.0-beta.1"
  s.summary           = "Advanced Operations in Swift."
  s.homepage          = "https://github.com/ProcedureKit/ProcedureKit"
  s.license           = 'MIT'
  s.authors           = { "ProcedureKit Core Contributors" => "hello@procedure.kit.run" }
  s.source            = { :git => "https://github.com/ProcedureKit/ProcedureKit.git", :tag => s.version.to_s }
  s.module_name       = 'ProcedureKit'

  s.ios.deployment_target = '9.0'
  s.watchos.deployment_target = '3.0'
  s.tvos.deployment_target = '9.2'
  s.osx.deployment_target = '10.11'
  
  # Ensure the correct version of Swift is used
  s.swift_version = '4.1'

  # Default spec is 'Standard'
  s.default_subspec = 'Standard'

  # Default core framework suitable for an iOS, watchOS, tvOS or macOS application
  s.subspec 'Standard' do |ss|
    ss.source_files = ['Sources/ProcedureKit']
    ss.exclude_files = [
      'Sources/TestingProcedureKit',
      'Sources/ProcedureKitMobile',
      'Sources/ProcedureKitMac',
      'Sources/ProcedureKitTV',
      'Sources/ProcedureKitNetwork',
      'Sources/ProcedureKitCloud',
      'Sources/ProcedureKitLocation'
    ]
  end

  # ProcedureKitNetwork
  s.subspec 'Network' do |ss|
  	ss.dependency 'ProcedureKit/Standard'
  	ss.source_files = ['Sources/ProcedureKitNetwork']
  end

  # ProcedureKitCloud
  s.subspec 'Cloud' do |ss|
  	ss.dependency 'ProcedureKit/Standard'
  	ss.frameworks = 'CloudKit'
  	ss.source_files = ['Sources/ProcedureKitCloud']
  end

  # ProcedureKitCoreData
  s.subspec 'CoreData' do |ss|
  	ss.dependency 'ProcedureKit/Standard'
  	ss.frameworks = 'CoreData'
  	ss.source_files = ['Sources/ProcedureKitCoreData']
  end

  # ProcedureKitLocation
  s.subspec 'Location' do |ss|
  	ss.dependency 'ProcedureKit/Standard'
  	ss.frameworks = 'CoreLocation', 'MapKit'
  	ss.source_files = ['Sources/ProcedureKitLocation']
  end

  # All cross-platform ProcedureKit
  s.subspec 'All' do |ss|
  	ss.dependency 'ProcedureKit/Network'
  	ss.dependency 'ProcedureKit/Location'
  	ss.dependency 'ProcedureKit/CoreData'  	
  	ss.dependency 'ProcedureKit/Cloud'
  end

  # ProcedureKitMobile
  s.subspec 'Mobile' do |ss|
    ss.platforms = { :ios => "8.0" }
  	ss.dependency 'ProcedureKit/Standard'
  	ss.source_files = ['Sources/ProcedureKitMobile']
  end
  
end
