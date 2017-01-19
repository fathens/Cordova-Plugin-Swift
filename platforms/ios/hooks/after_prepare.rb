#!/usr/bin/env ruby

require 'pathname'
require 'rexml/document'
require_relative '../../../lib/cordova_plugin_swift'

$PROJECT_DIR = Pathname.pwd.realpath
$PLATFORM_DIR = $PROJECT_DIR/'platforms'/'ios'

swift_version = '3.0'

log "Using swift_version: #{swift_version}"
open($PLATFORM_DIR/'cordova'/'build.xcconfig', 'a') { |f|
    f.puts "SWIFT_VERSION = #{swift_version}"
}

headers = CordovaPluginSwift.bridging_headers($PROJECT_DIR)
bridging_file = Pathname.glob($PLATFORM_DIR/'*'/'Bridging-Header.h').first
if (bridging_file && !headers.empty?) then
    File.open(bridging_file, 'a') { |dst|
        dst.puts()
        dst.puts "// Below add by cordova-plugin-swift"
        dst.puts headers
    }
end
