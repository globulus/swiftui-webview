Pod::Spec.new do |s|
  s.name             = 'SwiftUIWebView'
  s.version          = '1.0.8'
  s.summary          = 'Fully functional, SwiftUI-ready WebView for iOS 13+ and MacOS 10.15+.'
  s.homepage         = 'https://github.com/globulus/swiftui-webview'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Gordan Glavaš' => 'gordan.glavas@gmail.com' }
  s.source           = { :git => 'https://github.com/globulus/swiftui-webview.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.swift_version = '4.0'
  s.source_files = 'Sources/SwiftUIWebView/**/*'
end
