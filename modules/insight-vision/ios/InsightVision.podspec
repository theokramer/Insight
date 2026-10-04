Pod::Spec.new do |s|
  s.name = 'InsightVision'
  s.version = '1.0.0'
  s.summary = 'Private local PDF rendering and OCR for Insight'
  s.description = s.summary
  s.license = { :type => 'MIT' }
  s.author = 'Insight'
  s.homepage = 'https://github.com/theokramer/Insight'
  s.platforms = { :ios => '16.0' }
  s.source = { :git => '' }
  s.static_framework = true
  s.dependency 'ExpoModulesCore'
  s.frameworks = 'PDFKit', 'Vision', 'UIKit'
  s.swift_version = '5.9'
  s.source_files = '**/*.{h,m,mm,swift}'
end
