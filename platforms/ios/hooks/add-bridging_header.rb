#!/usr/bin/env ruby

require 'xcodeproj'

header_file=$1

puts "################################"
puts "#### Add Swift Bridging Header: $header_file"

proj = Dir.glob('*.xcodeproj')
puts "Using #{proj}"

project = Xcodeproj::Project.open proj

union_file = project.targets.first.build_configurations.first.build_settings["SWIFT_OBJC_BRIDGING_HEADER"]
puts "Fixing #{union_file}"

File.open(union_file.path, "a") { |dst|
  ARGV.each { |src_path|
    puts "Appending #{src_path}"
    File.open(src_path) { |src|
        dst << src.read
    }
  }
}
