#
# Be sure to run `pod lib lint CoreMeteor.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MHMeteor"
  s.version          = "0.2.0"
  s.summary          = "A short description of MHMeteor."
  s.description      = <<-DESC
                       An optional longer description of MHMeteor

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/malhal/MHMeteor"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Malcolm Hall" => "malhal@users.noreply.github.com" }
  s.source           = { :git => "https://github.com/malhal/MHMeteor.git",
                         :tag => s.version.to_s,
                         :submodules => true
                       }
  s.social_media_url = 'https://twitter.com/malhal'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'MHMeteor/**/*.{h,m}', 'dependencies/**/*.{h,m}'

#spec.subspec 'SDKit' do |sdkit|
#sdkit.source_files = 'dependencies/**/*.{h,m}'
#sdkit.resources    = 'SDKit/**/Assets/*.png'
#end

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreData', 'JavaScriptCore'
  # s.dependency 'AFNetworking', '~> 2.3'
end
