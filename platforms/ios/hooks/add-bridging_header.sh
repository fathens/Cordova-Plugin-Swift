#!/bin/bash
set -eu

header_file=$1

echo "################################"
echo "#### Add Swift Bridging Header: $header_file"

proj="${2:-$(find . -maxdepth 1 -name '*.xcodeproj')}"
echo "Fixing $(pwd)/$proj"

cat <<EOF | ruby
require 'xcodeproj'

project = Xcodeproj::Project.open "$proj"

union_file = project.targets.first.build_configurations.first.build_settings["SWIFT_OBJC_BRIDGING_HEADER"]

File.open("$header_file") { |src|
    File.open(union_file.path, "a") { |dst|
        dst << src.read
    }
}

EOF
