#
# Be sure to run `pod lib lint CoreMeteor.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CoreMeteor"
  s.version          = "0.1.2"
  s.summary          = "A short description of CoreMeteor."
  s.description      = <<-DESC
                       An optional longer description of CoreMeteor

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/malcolmhall/CoreMeteor"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Malcolm Hall" => "malcolmhall@users.noreply.github.com" }
  s.source           = { :git => "https://github.com/malcolmhall/CoreMeteor.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/malhal'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'CoreMeteor/'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'Foundation', 'CoreData', 'JavaScriptCore'
  # s.dependency 'AFNetworking', '~> 2.3'
end
