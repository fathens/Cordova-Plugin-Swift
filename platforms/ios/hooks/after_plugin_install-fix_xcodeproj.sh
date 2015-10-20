#!/bin/bash
set -eu

plugin_id=$1

echo "################################"
echo "#### Fix project.pbxproj"

proj="$(find . -maxdepth 1 -name '*.xcodeproj')"
echo "Fixing $(pwd)/$proj"

project_name="$(basename "${proj%%.xcodeproj}")"

cat <<EOF | ruby
require 'xcodeproj'

def build_settings(project, params)
    project.targets.each do |target|
        target.build_configurations.each do |conf|
            puts "On config: #{conf}"
            params.each do |key, value|
                puts "Putting '#{key}'='#{value}'"
                conf.build_settings[key] = value
            end
        end
    end
end

project = Xcodeproj::Project.open "$proj"
project.recreate_user_schemes

build_settings(project,
    "OTHER_LDFLAGS" => "\$(inherited)",
    "ENABLE_BITCODE" => "NO",
    "SWIFT_OBJC_BRIDGING_HEADER" => "${project_name}/Plugins/${plugin_id}/union-Bridging-Header.h"
)

project.save
sleep 1
puts "Saved: #{project}"
EOF

grep SWIFT_OBJC_BRIDGING_HEADER "$proj/*"
