#!/bin/zsh
# Regenerates the Xcode project and runs the core's unit tests.
set -euo pipefail
cd "${0:A:h}"
xcodegen generate --quiet
xcodebuild test \
  -project Bouncer.xcodeproj \
  -scheme Bouncer \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  -quiet "$@"
