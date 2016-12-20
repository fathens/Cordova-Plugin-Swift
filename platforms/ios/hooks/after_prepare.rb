#!/usr/bin/env ruby

require 'pathname'
require 'rexml/document'
require_relative '../../../lib/cordova_plugin_swift'

def load_podfile(base_dir, ios_version, swift_version)
    podfile = Pathname.glob(base_dir/'plugins'/'*'/'plugin.xml').map { |xmlFile|
        begin
            Podfile.from_pluginxml(xmlFile)
        rescue => ex
            puts "Error on '#{xmlFile}': #{ex.message}"
        end
    }.compact.reduce(Podfile.new(ios_version: ios_version, swift_version: swift_version)) { |a, b|
        a.merge b
    }

    raise "Require down version of iOS in plugins: #{podfile.ios_version} < #{ios_version}" if podfile.ios_version < ios_version

    podfile
end

def bridging(podfile, target_file)
    headers = podfile.pods.map {|p| p.bridging_headers }.flatten

    File.open(target_file, 'a') { |dst|
        dst.puts()
        dst.puts "// Below add by Cordova-Plugin-Swift"
        dst.puts headers.map(&:to_s)
    }
end

def removeImport(files)
    files.each { |fileSrc|
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

$PROJECT_DIR = Pathname.pwd.realpath
$PLATFORM_DIR = $PROJECT_DIR/'platforms'/'ios'
ENV['PLUGIN_DIR'] = Pathname($0).realpath.dirname.dirname.dirname.dirname.to_s

config = ConfigXml.new($PROJECT_DIR/'config.xml')
$APPLICATION_NAME = config.application_name

log_header "Loading podfile..."
podfile = load_podfile($PROJECT_DIR, config.ios_version || '9.0', '3.0')
log "Using ios_version: #{podfile.ios_version}"
log "Using swift_version: #{podfile.swift_version}"

podfile.write($PLATFORM_DIR/'Podfile', $APPLICATION_NAME)
Dir.chdir($PLATFORM_DIR) {
    system "pod install"
}

log_header "Removing unnecessary imports..."
removeImport Pathname.glob($PLATFORM_DIR/$APPLICATION_NAME/'Plugins'/'**'/'*.swift')

bridging podfile, $PLATFORM_DIR/$APPLICATION_NAME/'Bridging-Header.h'

log_header "Modify xcconfig..."

open($PLATFORM_DIR/'cordova'/'build-extras.xcconfig', 'a') { |f|
    f.puts "SWIFT_VERSION = #{podfile.swift_version}"
}
["debug", "release"].each { |key|
    open($PLATFORM_DIR/'cordova'/"build-#{key}.xcconfig", 'a') { |f|
        f.puts "\#include \"#{$PLATFORM_DIR/'Pods'/'Target Support Files'/"Pods-#{$APPLICATION_NAME}"/"Pods-#{$APPLICATION_NAME}.#{key}.xcconfig"}\""
    }
}
