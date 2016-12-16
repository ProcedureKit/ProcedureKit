Pod::Spec.new do |s|
  s.name              = "TestingProcedureKit"
  s.version           = "4.0.0"
  s.summary           = "XCTest support for ProcedureKit."
  s.description       = <<-DESC
  
A Swift framework inspired by Apple's WWDC 2015
session Advanced NSOperations: https://developer.apple.com/videos/wwdc/2015/?id=226.

                       DESC
  s.homepage          = "https://github.com/ProcedureKit/ProcedureKit"
  s.license           = 'MIT'
  s.authors           = { "ProcedureKit Core Contributors" => "hello@procedure.kit.run" }
  s.source            = { :git => "https://github.com/ProcedureKit/ProcedureKit.git", :tag => "4.0.0.beta.6" }
  s.module_name       = 'TestingProcedureKit'
  s.social_media_url  = 'https://twitter.com/danthorpe'
  s.requires_arc      = true
  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.2'
  s.osx.deployment_target = '10.10'
  
  s.frameworks = 'XCTest'
  
  # Ensure the correct version of Swift is used
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }

  # Defaul spec is 'Testing'
  s.default_subspec   = 'Testing'

  # TestingProcedureKit
  s.subspec 'Testing' do |ss|
    ss.platforms = { :ios => "8.0", :tvos => "9.2", :osx => "10.10" }  
  	ss.dependency 'ProcedureKit'  
  	ss.frameworks = 'XCTest'  	
  	ss.source_files = ['Sources/Testing']
  end
end


