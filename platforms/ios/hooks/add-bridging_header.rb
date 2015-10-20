#!/usr/bin/env ruby

require 'rexml/document'
require 'xcodeproj'

puts "################################"
puts "#### pod install"

system "pod install"

puts "################################"
puts "#### Add Swift Bridging Header"

proj = Dir.glob('platforms/ios/*.xcodeproj')[0]
puts "Editing #{proj}"

union_file = Pathname(ENV['CORDOVA_HOOK']).dirname.parent.join('union-Bridging-Header.h').realpath.to_path
puts "Union Header: #{union_file}"

File.open(union_file, "a") { |dst|
  Dir.glob('plugins/*/plugin.xml').each { |xmlFile|
    begin
      xml = REXML::Document.new(File.open(xmlFile))
      xml.elements.each('plugin/platform/bridging-header-file') { |elm|
        src_path = Pathname(xmlFile).dirname.join(elm.attributes['src']).to_path
        puts "Appending #{src_path}"
        File.open(src_path) { |src|
            dst << src.read
        }
      }
    rescue => ex
      puts "Error on '#{xmlFile}': #{ex.message}"
    end
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
project.recrate_user_schemes

build_settings(project,
    "OTHER_LDFLAGS" => "\$(inherited)",
    "ENABLE_BITCODE" => "NO",
    "SWIFT_OBJC_BRIDGING_HEADER" => union_file
)

project.save
