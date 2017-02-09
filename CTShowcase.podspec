Pod::Spec.new do |s|
  s.name             = "CTShowcase"
  s.version          = "2.1.0"
  s.summary          = "Highlight individual views in your app using static or dynamic effects."
  s.homepage         = "https://github.com/scihant/CTShowcase"
  s.screenshots      = "https://s3.amazonaws.com/tek-files/static.png", "https://s3.amazonaws.com/tek-files/dynamic_rect.gif", "https://s3.amazonaws.com/tek-files/dynamic_circle.gif"
  s.license          = "MIT"
  s.author           = { "scihant" => "cihantek@gmail.com" }
  s.source           = { :git => "https://github.com/scihant/CTShowcase.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Source/*.{swift}'
  s.frameworks = 'UIKit'
end
