Pod::Spec.new do |s|
  s.name              = "Operations"
  s.version           = "2.4.1"
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
  s.documentation_url = 'http://docs.danthorpe.me/operations/2.4.0/index.html'
  s.social_media_url  = 'https://twitter.com/danthorpe'
  s.requires_arc      = true
  s.default_subspec   = 'App'
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"

  # Creates a framework suitable for an iOS or Mac OS application
  s.subspec 'App' do |ss|
    ss.source_files      = [
      'Operations/Core/Shared', 
      'Operations/Core/iOS',       
      'Operations/Features/Shared',
      'Operations/Features/iOS'      
    ]
    ss.osx.exclude_files = [
      'Operations/Core/iOS',
      'Operations/Features/iOS'
    ]
  end

  s.subspec '+AddressBook' do |ss|
    ss.dependency 'Operations/App'
    ss.source_files = [
      'Operations/Extras/AddressBook/iOS',
      'Operations/Extras/Contacts/Shared',
      'Operations/Extras/Contacts/iOS'
    ]
    ss.osx.exclude_files = [
      'Operations/Extras/AddressBook/iOS',
      'Operations/Extras/Contacts/iOS'
    ]
  end

  # Creates a framework suitable for an (iOS or watchOS) Extension
  s.subspec 'Extension' do |ss|
    ss.source_files = [
      'Operations/Core/Shared', 
      'Operations/Core/iOS',       
      'Operations/Features/Shared',
      'Operations/Features/iOS'      
    ]  
    ss.osx.exclude_files = [
      'Operations/Core/iOS',
      'Operations/Features/iOS'
    ]      
    ss.exclude_files = [
      'Operations/Core/iOS/BackgroundObserver.swift',
      'Operations/Core/iOS/NetworkObserver.swift',
      'Operations/Features/iOS/HealthCapability.swift',
      'Operations/Features/iOS/LocationCapability.swift',
      'Operations/Features/iOS/LocationOperations.swift',
      'Operations/Features/iOS/RemoteNotificationCondition.swift',
      'Operations/Features/iOS/UserNotificationCondition.swift',
    ]
  end

  # Creates a framework suitable for an iOS watchOS 2 app

  s.subspec 'watchOS' do |ss|
    ss.platform = :watchos
    ss.source_files = [
      'Operations/Core/Shared',
      'Operations/Core/iOS',
      'Operations/Features/Shared',
      'Operations/Features/iOS'
    ]
    ss.exclude_files = [
      'Operations/Core/iOS/BackgroundObserver.swift',
      'Operations/Core/iOS/NetworkObserver.swift',
      'Operations/Core/iOS/AlertOperation.swift',
      'Operations/Core/iOS/UIOperation.swift',
      'Operations/Features/iOS/LocationCapability.swift',
      'Operations/Features/iOS/LocationOperations.swift',
      'Operations/Features/iOS/PhotosCapability.swift',
      'Operations/Features/iOS/RemoteNotificationCondition.swift',
      'Operations/Features/iOS/UserConfirmationCondition.swift',
      'Operations/Features/iOS/UserNotificationCondition.swift',
      'Operations/Features/iOS/WebpageOperation.swift',
      'Operations/Features/Shared/CloudCapability.swift',
      'Operations/Features/Shared/ReachabilityCondition.swift',
      'Operations/Features/Shared/CloudKitOperation.swift',
      'Operations/Features/Shared/ReachableOperation.swift',
      'Operations/Features/Shared/Reachability.swift',
    ]
  end
  
#  Creates a framework suitable for a tvOS app

  s.subspec 'tvOS' do |ss|
    ss.platform = :tvos
    ss.source_files = [
      'Operations/Core/Shared',
      'Operations/Core/iOS',
      'Operations/Features/Shared',
      'Operations/Features/iOS'
    ]
    ss.exclude_files = [
      'Operations/Features/iOS/HealthCapability.swift',
      'Operations/Features/iOS/LocationCapability.swift',
      'Operations/Features/iOS/LocationOperations.swift',      
      'Operations/Features/iOS/PassbookCapability.swift',
      'Operations/Features/iOS/PhotosCapability.swift',
      'Operations/Features/iOS/RemoteNotificationCondition.swift',
      'Operations/Features/iOS/UserNotificationCondition.swift',
      'Operations/Features/iOS/WebpageOperation.swift',
      'Operations/Features/Shared/CalendarCapability.swift',
      'Operations/Features/Shared/CloudCapability.swift',      
    ]
  end

end

