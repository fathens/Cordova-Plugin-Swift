require 'rexml/document'
version = REXML::Document.new(File.open('plugin.xml')).get_elements('/plugin').first.attributes['version']

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = "Cordova-Plugin-Swift"
  s.version     = version
  s.summary     = "A toolkit of support libraries for Cordova-Plugin-Swift"
  s.description = "A toolkit of support libraries for Cordova-Plugin-Swift"

  s.required_ruby_version = ">= 2.3.1"

  s.license = "MIT"

  s.author   = "Office f:athens"
  s.email    = "devel@fathens.org"
  s.homepage = "http://fathens.org"

  s.files        = Dir["LICENSE", "plugin.xml", "gemlib/**/*"]
  s.require_path = "gemlib"
end
