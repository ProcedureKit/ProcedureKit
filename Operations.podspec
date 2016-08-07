Pod::Spec.new do |s|
  s.name              = "Operations"
  s.version           = "3.1.0"
  s.summary           = "Powerful NSOperation subclasses in Swift."
  s.description       = <<-DESC
  
A Swift framework inspired by Apple's WWDC 2015
session Advanced NSOperations: https://developer.apple.com/videos/wwdc/2015/?id=226

                       DESC
  s.homepage          = "https://github.com/danthorpe/Operations"
  s.license           = 'MIT'
  s.author            = { "Daniel Thorpe" => "@danthorpe" }
  s.source            = { :git => "https://github.com/danthorpe/Operations.git", :tag => s.version.to_s }
  s.module_name       = 'Operations'
  s.social_media_url  = 'https://twitter.com/danthorpe'
  s.requires_arc      = true
  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  # Defaul spec is 'Standard'
  s.default_subspec   = 'Standard'

  # Creates a framework suitable for an iOS, watchOS, tvOS or Mac OS application
  s.subspec 'Standard' do |ss|
    ss.source_files = [
      'Sources/Core/Shared', 
      'Sources/Core/iOS',       
      'Sources/Features/Shared',
      'Sources/Features/iOS'
    ]
    ss.ios.exclude_files = [
      'Sources/Features/Shared/CloudKit',
      'Sources/Features/Shared/TaskOperation.swift',
      'Sources/Features/iOS/PhotosCapability.swift',
      'Sources/Features/iOS/PassbookCapability.swift'
    ]
    ss.watchos.exclude_files = [
      'Sources/Core/iOS',
      'Sources/Features/Shared/CloudKit',
      'Sources/Features/Shared/ReachabilityCondition.swift',
      'Sources/Features/Shared/ReachableOperation.swift',
      'Sources/Features/Shared/Reachability.swift',
      'Sources/Features/Shared/TaskOperation.swift',      
      'Sources/Features/iOS/LocationCapability.swift',
      'Sources/Features/iOS/LocationOperations.swift',
      'Sources/Features/iOS/PhotosCapability.swift',
      'Sources/Features/iOS/RemoteNotificationCondition.swift',
      'Sources/Features/iOS/UserConfirmationCondition.swift',
      'Sources/Features/iOS/UserNotificationCondition.swift',
      'Sources/Features/iOS/WebpageOperation.swift',
      'Sources/Features/iOS/OpenInSafariOperation.swift'
    ]
    ss.tvos.exclude_files = [
      'Sources/Features/Shared/CloudKit',    
      'Sources/Features/Shared/CalendarCapability.swift',      
      'Sources/Features/Shared/TaskOperation.swift',                  
      'Sources/Features/iOS/HealthCapability.swift',
      'Sources/Features/iOS/LocationCapability.swift',
      'Sources/Features/iOS/LocationOperations.swift',      
      'Sources/Features/iOS/PassbookCapability.swift',
      'Sources/Features/iOS/PhotosCapability.swift',
      'Sources/Features/iOS/RemoteNotificationCondition.swift',
      'Sources/Features/iOS/UserNotificationCondition.swift',
      'Sources/Features/iOS/WebpageOperation.swift',
      'Sources/Features/iOS/OpenInSafariOperation.swift'
    ]
    ss.osx.exclude_files = [
      'Sources/Core/iOS',
      'Sources/Features/iOS',
      'Sources/Features/Shared/CloudKit'
    ]
  end

  # Creates a framework suitable for an (iOS, tvOS or OS X) Extension
  s.subspec 'Extension' do |ss|
    ss.platforms = { :ios => "8.0", :tvos => "9.0", :osx => "10.10" }
    ss.source_files = [
      'Sources/Core/Shared',
      'Sources/Core/iOS',
      'Sources/Features/Shared',
      'Sources/Features/iOS'
    ]
    ss.exclude_files = [
      'Sources/Core/iOS/BackgroundObserver.swift',
      'Sources/Core/iOS/NetworkObserver.swift',
      'Sources/Features/Shared/TaskOperation.swift',
      'Sources/Features/iOS/HealthCapability.swift',
      'Sources/Features/iOS/LocationCapability.swift',
      'Sources/Features/iOS/LocationOperations.swift',
      'Sources/Features/iOS/OpenInSafariOperation.swift',      
      'Sources/Features/iOS/RemoteNotificationCondition.swift',      
      'Sources/Features/iOS/UserNotificationCondition.swift'
    ]
    ss.tvos.exclude_files = [
      'Sources/Features/iOS/PassbookCapability.swift',
      'Sources/Features/iOS/PhotosCapability.swift',
      'Sources/Features/iOS/WebpageOperation.swift',
      'Sources/Features/iOS/OpenInSafariOperation.swift',      
      'Sources/Features/Shared/CalendarCapability.swift'
    ]
    ss.osx.exclude_files = [
      'Sources/Core/iOS',
      'Sources/Features/iOS'
    ]
  end

  # Subspec which includes HealthCondition. Note that this
  # will import HealthKit, which means that when submitting
  # to the AppStore, special notes regarding the usage of
  # HealthKit.
  s.subspec '+Health' do |ss|
    ss.platforms = { :ios => "8.0", :watchos => "2.0" }
    ss.dependency 'Operations/Standard'
    ss.source_files = [
      'Sources/Extras/Health/iOS'
    ]
  end

  # Subspec which includes AddressBook & Contact functionality
  s.subspec '+AddressBook' do |ss|
    ss.platforms = { :ios => "8.0", :osx => "10.10" }
    ss.dependency 'Operations/Standard'
    ss.source_files = [
      'Sources/Extras/AddressBook/iOS',
      'Sources/Extras/Contacts/Shared',
      'Sources/Extras/Contacts/iOS'
    ]
    ss.osx.exclude_files = [
      'Sources/Extras/AddressBook/iOS',
      'Sources/Extras/Contacts/iOS'
    ]
  end
	
  # Subspec which includes CloudKit functionality
  s.subspec '+CloudKit' do |ss|
    ss.platforms = { :ios => "8.0", :tvos => "9.0", :osx => "10.10" }
    ss.dependency 'Operations/Standard'
    ss.frameworks = 'CloudKit'    
    ss.source_files = [
      'Sources/Features/Shared/CloudKit'
    ]
  end
	
  # Subspec which includes Photos functionality
  s.subspec '+Photos' do |ss|
    ss.platforms = { :ios => "8.0" }
    ss.dependency 'Operations/Standard'
    ss.frameworks = 'Photos'
    ss.source_files = [
      'Sources/Features/iOS/PhotosCapability.swift'
    ]
  end
	
  # Subspec which includes Passbook functionality
  s.subspec '+Passbook' do |ss|
    ss.platforms = { :ios => "8.0" }
    ss.dependency 'Operations/Standard'
    ss.frameworks = 'PassKit'
    ss.source_files = [
      'Sources/Features/iOS/PassbookCapability.swift'
    ]
  end
end


