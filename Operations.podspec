Pod::Spec.new do |s|
  s.name              = "Operations"
  s.version           = "2.0.2"
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
  s.default_subspec   = 'Features'
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"

  s.subspec 'Core' do |ss|
    ss.source_files      = 'Operations/Core/**/*.swift'
    ss.osx.exclude_files = 'Operations/Core/iOS/*.swift'
  end

  s.subspec 'Features' do |ss|
    ss.dependency 'Operations/Core'    
    ss.source_files      = 'Operations/Features/**/*.swift'
    ss.osx.exclude_files = 'Operations/Features/iOS/*.swift'    
  end

  s.subspec '+AddressBook' do |ss|
    ss.platform = :ios, "8.0"
    ss.dependency 'Operations/Features'
    ss.source_files   = 'Operations/Extras/AddressBook/iOS/*.swift'
  end

  s.subspec 'Extension' do |ss|
    ss.dependency 'Operations/Features'
    ss.ios.exclude_files = [
      'Operations/Core/iOS/BackgroundObserver.swift',
      'Operations/Core/iOS/NetworkObserver.swift',
      'Operations/Features/Shared/CalendarCondition.swift',
      'Operations/Features/iOS/RemoteNotificationCondition.swift',
      'Operations/Features/iOS/UserNotificationCondition.swift',
      'Operations/Features/iOS/HealthCondition.swift',
      'Operations/Features/iOS/LocationCondition.swift',
      'Operations/Features/iOS/ReachabilityCondition.swift',
      'Operations/Features/iOS/LocationOperation.swift',
      'Operations/Features/iOS/WebpageOperation.swift',
    ]
  end

  s.subspec 'watchOS' do |ss|
    ss.platform = :ios, "9.0"
    ss.dependency 'Operations/Features'
    ss.ios.exclude_files = [
      'Operations/Core/iOS/BackgroundObserver.swift',
      'Operations/Core/iOS/NetworkObserver.swift',
      'Operations/Core/iOS/AlertOperation.swift',
      'Operations/Core/iOS/UIOperation.swift',            
      'Operations/Features/Shared/CloudCondition.swift',
      'Operations/Features/iOS/PhotosCondition.swift',      
      'Operations/Features/iOS/RemoteNotificationCondition.swift',
      'Operations/Features/iOS/UserConfirmationCondition.swift',      
      'Operations/Features/iOS/UserNotificationCondition.swift',
      'Operations/Features/iOS/LocationCondition.swift',
      'Operations/Features/Shared/ReachabilityCondition.swift',
      'Operations/Features/Shared/CloudKitOperation.swift',      
      'Operations/Features/iOS/LocationOperation.swift',
      'Operations/Features/Shared/ReachableOperation.swift',      
      'Operations/Features/iOS/WebpageOperation.swift',
      'Operations/Features/Shared/Reachability.swift',      
    ]
  end
  
  s.subspec 'tvOS' do |ss|
    ss.platform = :ios, "9.0"
    ss.dependency 'Operations/Features'
    ss.ios.exclude_files = [
      'Operations/Features/Shared/CalendarCondition.swift',
      'Operations/Features/iOS/PassbookCondition.swift',      
      'Operations/Features/iOS/PhotosCondition.swift',            
      'Operations/Features/iOS/RemoteNotificationCondition.swift',
      'Operations/Features/iOS/UserNotificationCondition.swift',
      'Operations/Features/iOS/HealthCondition.swift',
      'Operations/Features/iOS/LocationCondition.swift',
      'Operations/Features/iOS/LocationOperation.swift',
      'Operations/Features/iOS/WebpageOperation.swift',
    ]    
  end

end

