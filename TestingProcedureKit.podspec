Pod::Spec.new do |s|
  s.name              = "TestingProcedureKit"
  s.version           = "5.0.0-beta.1"
  s.summary           = "XCTest support for ProcedureKit."
  s.homepage          = "https://github.com/ProcedureKit/ProcedureKit"
  s.license           = 'MIT'
  s.authors           = { "ProcedureKit Core Contributors" => "hello@procedure.kit.run" }
  s.source            = { :git => "https://github.com/ProcedureKit/ProcedureKit.git", :tag => s.version.to_s }
  s.module_name       = 'TestingProcedureKit'

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.2'
  s.osx.deployment_target = '10.11'
  
  s.frameworks = 'XCTest'
  
  # Ensure the correct version of Swift is used
  s.swift_version = '4.1'

  # Defaul spec is 'Testing'
  s.default_subspec   = 'Testing'

  # TestingProcedureKit
  s.subspec 'Testing' do |ss|
  	ss.dependency 'ProcedureKit'
  	ss.frameworks = 'XCTest'  	
  	ss.source_files = ['Sources/TestingProcedureKit']
  end
end


