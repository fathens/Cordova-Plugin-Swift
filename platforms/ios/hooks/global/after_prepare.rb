#!/usr/bin/env ruby

require 'rexml/document'
require 'xcodeproj'

$PROJECT_DIR = Pathname('.').realpath
$PLATFORM_DIR = Pathname('platforms').join('ios').realpath

def plugin_id
  curPlugin = Pathname(ENV['CORDOVA_HOOK']).dirname.dirname.dirname.dirname.dirname.join('plugin.xml')
  curXml = REXML::Document.new(File.open(curPlugin))
  return curXml.elements['plugin'].attributes['id']
end

class AllPlugins
  @header_files
  @pods
  @union_file
  def initialize
    @header_files = []
    @pods = []
    @union_file = Pathname.glob($PLATFORM_DIR.join('*').join('Plugins').join(plugin_id).join('union-Bridging-Header.h'))[0]
    Pathname.glob($PROJECT_DIR.join('plugins').join('*').join('plugin.xml')).each { |xmlFile|
      begin
        xml = REXML::Document.new(File.open(xmlFile))
        xml.elements.each('plugin/platform/bridging-header-file') { |elm|
          @header_files << xmlFile.dirname.join(elm.attributes['src'])
        }
        xml.elements.each('plugin/platform/podfile/pod') { |elm|
          @pods << elm
        }
      rescue => ex
        puts "Error on '#{xmlFile}': #{ex.message}"
      end
    }
  end
  
  def union_file
    return @union_file
  end
  
  def append_union_header
    lines = []
    @header_files.each { |file|
      puts "Header #{file}"
      File.open(file) { |f|
        lines.concat f.readlines
      }
    }

    puts "Union Header: #{union_file}"
    File.open(union_file, "w+") { |dst|
      lines.concat dst.readlines
      dst << lines.uniq.join
    }
  end
  
  def append_podfile
    lines = []
    @pods.each { |elm|
      args = [elm.attributes['name'], elm.attributes['version']]
      puts "Pod #{args}"
      line = args.select { |a|
        a != nil
      }.map { |a|
        "'" + a + "'"
      }.join(', ')
      lines << "pod #{line}"
    }
    podfile = $PLATFORM_DIR.join('Podfile')
    puts "Podfile: #{podfile}"
    File.open(podfile, "a") { |dst|
      dst << lines.uniq.join("\n")
    }
  end
end

class FixXcodeproj
  @project
  def initialize(file)
    puts "Editing #{file}"
    
    @project = Xcodeproj::Project.open(file)
    @project.recreate_user_schemes
  end
  
  def build_settings(params)
    @project.targets.each do |target|
      target.build_configurations.each do |conf|
        params.each do |key, value|
          conf.build_settings[key] = value
        end
      end
    end
  end
  
  def save
    @project.save
  end
end

if __FILE__ == $0
  plugins = AllPlugins.new
  plugins.append_union_header
  plugins.append_podfile
  
  # On Platform Dir
  Dir.chdir $PLATFORM_DIR
  
  system "pod install"
  
  xcode = FixXcodeproj.new(Pathname.glob('*.xcodeproj')[0])
  xcode.build_settings(
  "LD_RUNPATH_SEARCH_PATHS" => "\$(inherited) @executable_path/Frameworks",
  "OTHER_LDFLAGS" => "\$(inherited)",
  "ENABLE_BITCODE" => "NO",
  "SWIFT_OBJC_BRIDGING_HEADER" => plugins.union_file.relative_path_from($PLATFORM_DIR)
  )
  xcode.save
end
