#!/usr/bin/env ruby

require 'rexml/document'
require 'xcodeproj'

puts "################################"
puts "#### Add Swift Bridging Header"

proj = Dir.glob('platforms/ios/*.xcodeproj')[0]
puts "Editing #{proj}"

union_file = Pathname(ENV['CORDOVA_HOOK']).dirname.parent.join('union-Bridging-Header.h').realpath.to_path
puts "Union Header: #{union_file}"

File.open(union_file, "a") { |dst|
  ENV['CORDOVA_PLUGINS'].split(',').each { |plugin|
    xml = REXML::Document.new(File.open("plugins/#{plugin}/plugin.xml"))
    xml.elements.each('root/platform/bridging-header-file') { |elm|
      src_path = elm.attributes['src']
      puts "Appending #{src_path}"
      File.open(src_path) { |src|
          dst << src.read
      }
    }
  }
}

def build_settings(project, params)
    project.targets.each do |target|
        target.build_configurations.each do |conf|
            params.each do |key, value|
                conf.build_settings[key] = value
            end
        end
    end
end

project = Xcodeproj::Project.open proj

build_settings(project,
    "OTHER_LDFLAGS" => "\$(inherited)",
    "ENABLE_BITCODE" => "NO",
    "SWIFT_OBJC_BRIDGING_HEADER" => union_file
)

project.save
