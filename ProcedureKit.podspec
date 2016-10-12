Pod::Spec.new do |s|
  s.name              = "ProcedureKit"
  s.version           = "4.0.0-beta-2"
  s.summary           = "Powerful Operation subclasses in Swift."
  s.description       = <<-DESC
  
A Swift framework inspired by Apple's WWDC 2015
session Advanced NSOperations: https://developer.apple.com/videos/wwdc/2015/?id=226.

                       DESC
  s.homepage          = "https://github.com/ProcedureKit/ProcedureKit"
  s.license           = 'MIT'
  s.authors           = { "ProcedureKit Core Contributors" => "hello@procedure.kit.run" }
  s.source            = { :git => "https://github.com/ProcedureKit/ProcedureKit.git", :tag => s.version.to_s }
  s.module_name       = 'ProcedureKit'
  s.social_media_url  = 'https://twitter.com/danthorpe'
  s.requires_arc      = true
  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.2'
  s.osx.deployment_target = '10.10'
  
  # Ensure the correct version of Swift is used
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }

  # Defaul spec is 'Standard'
  s.default_subspec   = 'Standard'

  # Creates a framework suitable for an iOS, watchOS, tvOS or macOS application
  s.subspec 'Standard' do |ss|
    ss.source_files = ['Sources']
    ss.exclude_files = [
      'Sources/Testing',
      'Sources/Mobile',
      'Sources/Mac',
      'Sources/TV',
      'Sources/Cloud',
      'Sources/Location'
    ]
  end

end


