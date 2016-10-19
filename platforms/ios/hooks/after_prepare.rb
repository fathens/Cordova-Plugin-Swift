#!/usr/bin/env ruby

require 'pathname'
require 'json'
require 'rexml/document'

$PROJECT_DIR = Pathname('.').realpath
$PLATFORM_DIR = Pathname('platforms').join('ios').realpath

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
    podfile = $PLATFORM_DIR.join('Podfile')
    puts "Podfile: #{podfile}"
    File.open(podfile, "w") { |dst|
      dst.puts "platform :ios,'#{ios_version}'"
      dst.puts "use_frameworks!"
      dst.puts()
      dst.puts "target '#{ENV['APPLICATION_NAME']}' do"
      @pods.each { |elm|
        args = [elm.attributes['name'], elm.attributes['version']]
        puts "Pod #{args}"
        line = args.select { |a|
          a != nil
        }.map { |a|
          "'" + a + "'"
        }.join(', ')
        dst.puts "  pod #{line}"
      }
      dst.puts "end"
    }
  end
end

def removeImport
  Pathname.glob($PLATFORM_DIR/ENV['APPLICATION_NAME']/'Plugins'/'**'/'*.swift').each { |fileSrc|
    fileDst = "#{fileSrc}.rm"
    open(fileSrc, 'r') { |src|
      open(fileDst, 'w') { |dst|
        src.each_line { |line|
          if line =~ /^import +Cordova$/ then
            puts "Removing '#{line.strip}' from #{fileSrc}"
          else
            dst.puts line
          end
        }
      }
    }
    File.rename(fileDst, fileSrc)
  }
end

if __FILE__ == $0
  plugins = AllPlugins.new
  plugins.generate_podfile

  # On Platform Dir
  Dir.chdir $PLATFORM_DIR

  system "pod install"

  open($PLATFORM_DIR.join('cordova').join('build-extras.xcconfig'), 'a') { |f|
    f.puts "SWIFT_OBJC_BRIDGING_HEADER = $(SRCROOT)/#{ENV['APPLICATION_NAME']}/Bridging-Header.h"
  }
  ["debug", "release"].each { |key|
    open($PLATFORM_DIR.join('cordova').join("build-#{key}.xcconfig"), 'a') { |f|
      f.puts "\#include \"#{$PLATFORM_DIR.join('Pods').join('Target Support Files').join('Pods').join("Pods.#{key}.xcconfig")}\""
    }
  }

  removeImport
end
