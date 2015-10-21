#!/usr/bin/env ruby

require 'rexml/document'
require 'xcodeproj'

puts "################################"
puts "#### pod install"

system "(cd platforms/ios && pod install)"

puts "################################"
puts "#### Add Swift Bridging Header"

platformDir = Pathname('platforms').join('ios')

proj = Dir.glob(platformDir.join('*.xcodeproj').to_path)[0]
puts "Editing #{proj}"

plugin_id = Pathname(ENV['CORDOVA_HOOK']).dirname.dirname.dirname.basename

union_file = Dir.glob(platformDir.join('*').join('Plugins').join('*').join('union-Bridging-Header.h'))[0]
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
project.recreate_user_schemes

build_settings(project,
    "OTHER_LDFLAGS" => "\$(inherited)",
    "ENABLE_BITCODE" => "NO",
    "SWIFT_OBJC_BRIDGING_HEADER" => Pathname(union_file).relative_path_from(platformDir)
)

project.save
