require 'rexml/document'
version = REXML::Document.new(File.open('plugin.xml')).get_elements('/plugin').first.attributes['version']

Gem::Specification.new do |s|
    s.platform    = Gem::Platform::RUBY
    s.name        = "cordova_plugin_swift"
    s.version     = version
    s.summary     = "A toolkit of support libraries for Cordova-Plugin-Swift"

    s.required_ruby_version = ">= 2.3.1"

    s.license = "MIT"

    s.author   = "Office f:athens"
    s.email    = "devel@fathens.org"
    s.homepage = "http://fathens.org"

    s.files        = Dir["lib/**/*"] + Dir["bin/*"]
    s.bindir = "bin"
    s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

    s.add_runtime_dependency 'cocoapods', '~> 1.1'
    s.add_runtime_dependency 'xcodeproj', '~> 1.4'

    s.add_development_dependency "bundler", "~> 1.13"
    s.add_development_dependency "rake", "~> 10.0"
    s.add_development_dependency "rspec", "~> 3.0"
end
