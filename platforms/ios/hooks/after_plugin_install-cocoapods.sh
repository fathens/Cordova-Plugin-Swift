#!/bin/bash
set -eu

echo "################################"
echo "#### Add to Podfile"

cat <<EOF > Podfile
platform :ios,'8.0'

EOF

pod install