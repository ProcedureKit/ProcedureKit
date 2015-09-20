Pod::Spec.new do |s|
  s.name              = "Operations"
  s.version           = "2.0.2"
  s.summary           = "Powerful NSOperation subclasses in Swift."
  s.description       = <<-DESC

A Swift 1.2 framework inspired by Apple's WWDC 2015
session Advanced NSOperations: https://developer.apple.com/videos/wwdc/2015/?id=226

                       DESC
  s.homepage          = "https://github.com/danthorpe/Operations"
  s.license           = 'MIT'
  s.author            = { "Daniel Thorpe" => "@danthorpe" }
  s.source            = { :git => "https://github.com/danthorpe/Operations.git", :tag => s.version.to_s }
  s.module_name       = 'Operations'
  s.social_media_url  = 'https://twitter.com/danthorpe'
  s.requires_arc      = true
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"

  s.source_files      = [
    'Operations/Conditions/Shared',
    'Operations/Conditions/iOS',
    'Operations/Observers/Shared',
    'Operations/Observers/iOS',
    'Operations/Operations/Shared',
    'Operations/Operations/iOS',
    'Operations/Permissions/Shared',
    'Operations/Permissions/iOS',
    'Operations/Queue', 'Operations/*.{swift,h}'
  ]
  s.osx.exclude_files = [
    'Operations/Conditions/iOS',
    'Operations/Observers/iOS',
    'Operations/Operations/iOS',
    'Operations/Permissions/iOS',
  ]

  s.subspec '+AddressBook' do |ss|
    ss.source_files      = ['Operations/AddressBook/iOS']
    ss.osx.exclude_files = ['Operations/AddressBook/iOS']
  end

  s.subspec '+Extras' do |ss|
    ss.dependency 'Operations/+AddressBook'
  end
end
