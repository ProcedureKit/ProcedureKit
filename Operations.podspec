Pod::Spec.new do |s|
  s.name              = "Operations"
  s.version           = "1.0.0"
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
  s.platform          = :ios, '8.0'
  s.default_subspec   = 'Base'

  s.subspec 'Base' do |ss|
    ss.source_files      = 'Operations/**/*.{swift,m,h}'
    ss.exclude_files     = 'Operations/Extras/**/*.{swift,m,h}'
  end

  s.subspec '+AddressBook' do |ss|
    ss.dependency 'Operations/Base'    
    ss.source_files   = 'Operations/AddressBook/**/*.{swift,m,h}'
  end

  s.subspec '+Extras' do |ss|
    ss.dependency 'Operations/+AddressBook'
  end

end

