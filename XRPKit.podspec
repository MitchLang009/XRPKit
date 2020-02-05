#
# Be sure to run `pod lib lint XRPKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XRPKit'
  s.version          = '0.3.0'
  s.summary          = 'Swift SDK for interacting with XRP Ledger'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'XRPKit is a Swift SDK built for interacting with the XRP Ledger.  XRPKit supports offline wallet creation, offline transaction creation/signing, and submitting transactions to the XRP ledger.  XRPKit supports both the secp256k1 and ed25519 algorithms.  XRPKit is available on iOS, macOS and Linux (SPM)'

  s.homepage         = 'https://github.com/MitchLang009/XRPKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'MitchLang009' => 'mitch.s.lang@gmail.com' }
  s.source           = { :git => 'https://github.com/MitchLang009/XRPKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }

  s.source_files = 'Sources/XRPKit/**/*'
#  s.resources = 'XRPKit/Assets/*.xcassets'
  # s.resource_bundles = {
  #   'XRPKit' => ['XRPKit/Assets/*.png']
  # }

  s.dependency 'secp256k1.swift'
  s.dependency 'CryptoSwift'
  s.dependency 'BigInt'
  s.dependency 'AnyCodable-FlightSchool'
  s.dependency 'SwiftNIO', '~> 1.12.0'
  
  s.static_framework = true

end
