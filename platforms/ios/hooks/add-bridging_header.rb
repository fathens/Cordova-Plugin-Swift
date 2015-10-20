#!/usr/bin/env ruby

require 'rexml/document'
require 'xcodeproj'

puts "################################"
puts "#### Add Swift Bridging Header"

proj = Dir.glob('*.xcodeproj')
puts "Using #{proj}"

project = Xcodeproj::Project.open proj

union_file = project.targets.first.build_configurations.first.build_settings["SWIFT_OBJC_BRIDGING_HEADER"]
puts "Fixing #{union_file}"

File.open(union_file.path, "a") { |dst|
  ENV['CORDOVA_PLUGINS'].split(',').each { |plugin|
    xml = REXML::Document.new(open("plugins/#{plugin}/plugin.xml"))
    xml.elements.each('root/platform/bridging-header-file') { |elm|
      src_path = elm.attributes['src']
      puts "Appending #{src_path}"
      File.open(src_path) { |src|
          dst << src.read
      }
    }
  }
}
