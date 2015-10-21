#!/usr/bin/env ruby

require 'rexml/document'
require 'xcodeproj'

platformDir = Pathname('platforms').join('ios')

plugin_id = Pathname(ENV['CORDOVA_HOOK']).dirname.dirname.dirname.dirname.basename

union_file = Pathname.glob(platformDir.join('*').join('Plugins').join(plugin_id).join('union-Bridging-Header.h'))[0]
puts "Union Header: #{union_file}:"

lines = []
File.open(union_file) { |f|
  lines.concat f.readlines
}
Pathname.glob(Pathname('plugins').join('*').join('plugin.xml')).each { |xmlFile|
  begin
    xml = REXML::Document.new(File.open(xmlFile))
    xml.elements.each('plugin/platform/bridging-header-file') { |elm|
      src_path = xmlFile.dirname.join(elm.attributes['src'])
      puts "Appending #{src_path}"
      File.open(src_path) { |f|
        lines.concat f.readlines
      }
    }
  rescue => ex
    puts "Error on '#{xmlFile}': #{ex.message}"
  end
}

File.open(union_file, "w") { |dst|
  dst << lines.uniq.join('\n')
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

proj = Pathname.glob(platformDir.join('*.xcodeproj').to_path)[0]
puts "Editing #{proj}"

project = Xcodeproj::Project.open(proj)
project.recreate_user_schemes

build_settings(project,
    "OTHER_LDFLAGS" => "\$(inherited)",
    "ENABLE_BITCODE" => "NO",
    "SWIFT_OBJC_BRIDGING_HEADER" => union_file.relative_path_from(platformDir)
)

project.save
