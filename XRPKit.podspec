#
# Be sure to run `pod lib lint XRPKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XRPKit'
  s.version          = '0.2.1'
  s.summary          = 'XRP Ledger API'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'XRP Ledger API'

  s.homepage         = 'https://github.com/MitchLang009/XRPKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'MitchLang009' => 'mitch.s.lang@gmail.com' }
  s.source           = { :git => 'https://github.com/MitchLang009/XRPKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.platform = :osx, '10.10'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }

  s.source_files = 'XRPKit/Classes/**/*'
#  s.resources = 'XRPKit/Assets/*.xcassets'
  # s.resource_bundles = {
  #   'XRPKit' => ['XRPKit/Assets/*.png']
  # }

  s.public_header_files = 'XRPKit/Classes/Source/c++/GeneratorWrapper+Swift.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Alamofire'
  s.dependency 'FutureKit'
  s.dependency 'secp256k1.swift'
#  s.dependency 'CryptoSwift'
  s.dependency 'BigInt'
  s.dependency 'OpenSSL-Universal'

  s.static_framework = true
  s.libraries = 'c++'
end
