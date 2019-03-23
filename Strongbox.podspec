Pod::Spec.new do |s|
  s.name             = 'Strongbox'
  s.version          = '0.5.2'
  s.summary          = 'Strongbox is a Swift utility class for storing data securely in the keychain. Use it to store small, sensitive bits of data securely.'

  s.homepage         = 'https://github.com/granoff/Strongbox'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mark H. Granoff' => 'mark@granoff.net' }
  s.source           = { :git => 'https://github.com/granoff/Strongbox.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/granoff'

  s.ios.deployment_target = '9.0'
  s.watchos.deployment_target = '3.0'
  s.tvos.deployment_target = '9.0'
  
  s.source_files = 'Strongbox/Classes/**/*'  
  s.frameworks = 'Security'
end
