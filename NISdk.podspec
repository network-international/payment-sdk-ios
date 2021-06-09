#
#  Be sure to run `pod spec lint ni-sdk-ios.podspec'
#

Pod::Spec.new do |spec|

  spec.name = "NISdk"
  spec.version = "3.0.12"
  spec.summary = "Network International's Payment gateway sdk for iOS"

  spec.homepage = "https://docs.ngenius-payments.com/reference#ios-sdk"
  spec.license = "MIT"
  spec.author = "Network International"

  spec.platform = :ios, "11.0"
  spec.swift_version = "4.2"

  spec.source = { :git => 'https://github.com/network-international/payment-sdk-ios.git', :tag => "v#{spec.version}" }
  spec.source_files = 'NISdk/Source/**/*.{swift}'
  spec.resource_bundles = {
    'NISdk' => ["NISdk/Resources/**/*.{xcassets,otf,strings}"]
  }

  spec.frameworks = 'Foundation', 'Security', 'WebKit', 'PassKit'
  spec.requires_arc = true
end
