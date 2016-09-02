#!/usr/bin/env ruby

require 'json'
require 'rexml/document'
require 'xcodeproj'

$PROJECT_DIR = Pathname('.').realpath
$PLATFORM_DIR = Pathname('platforms').join('ios').realpath

def plugin_id
  file = Pathname(ENV['CORDOVA_HOOK']).dirname.dirname.dirname.dirname.dirname.join('plugin.xml')
  xml = REXML::Document.new(File.open(file))
  xml.elements['plugin'].attributes['id']
end

class AllPlugins
  def initialize
    @pods = []

    Pathname.glob($PROJECT_DIR.join('plugins').join('*').join('plugin.xml')).each { |xmlFile|
      begin
        xml = REXML::Document.new(File.open(xmlFile))
        xml.elements.each('plugin/platform/podfile/pod') { |elm|
          @pods << elm
        }
      rescue => ex
        puts "Error on '#{xmlFile}': #{ex.message}"
      end
    }
  end

  def generate_podfile
    def ios_version
      config_file = $PROJECT_DIR.join('config.xml')
      xml = REXML::Document.new(File.open(config_file))
      target = xml.elements["widget/preference[@name='deployment-target']"]
      if target != nil then
        target.attributes['value']
      else
        '9.0'
      end
    end
    def cordova_version
        json_file = $PROJECT_DIR.join('platforms', 'platforms.json')
        json = JSON.parse(File.read(json_file))
        vs = json['ios'].split('.').take(2)
        vs[vs.size() -1] = '0'
        "~> #{vs.join('.')}"
    end
    podfile = $PLATFORM_DIR.join('Podfile')
    puts "Podfile: #{podfile}"
    File.open(podfile, "w") { |dst|
      dst.puts "platform :ios,'#{ios_version}'"
      dst.puts "use_frameworks!"
      dst.puts()
      dst.puts "pod 'Cordova', '#{cordova_version}'"
      @pods.each { |elm|
        args = [elm.attributes['name'], elm.attributes['version']]
        puts "Pod #{args}"
        line = args.select { |a|
          a != nil
        }.map { |a|
          "'" + a + "'"
        }.join(', ')
        dst.puts "pod #{line}"
      }
    }
  end
end

class FixXcodeproj
  attr_reader :project
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
end

if __FILE__ == $0
  plugins = AllPlugins.new
  plugins.generate_podfile

  # On Platform Dir
  Dir.chdir $PLATFORM_DIR

  system "pod install"

  open($PLATFORM_DIR.join('cordova').join('build-extras.xcconfig'), 'a') { |f|
    f.puts "LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/Frameworks"
    f.puts "OTHER_LDFLAGS = $(inherited)"
    f.puts "SWIFT_OBJC_BRIDGING_HEADER ="
  }
  ["debug", "release"].each { |key|
    open($PLATFORM_DIR.join('cordova').join("build-#{key}.xcconfig"), 'a') { |f|
      f.puts "\#include \"#{$PLATFORM_DIR.join('Pods').join('Target Support Files').join('Pods').join("Pods.#{key}.xcconfig")}\""
    }
  }

  xcode = FixXcodeproj.new(Pathname.glob('*.xcodeproj')[0])
  xcode.build_settings(
  "LD_RUNPATH_SEARCH_PATHS" => "\$(inherited) @executable_path/Frameworks",
  "OTHER_LDFLAGS" => "\$(inherited)"
  )
  xcode.project.save
end
