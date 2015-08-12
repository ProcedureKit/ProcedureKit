#!/usr/bin/env bash
source /usr/local/opt/chruby/share/chruby/chruby.sh
chruby ruby

bundle update
set -o pipefail && bundle exec xcodebuild -project "Operations.xcodeproj" -scheme "Operations" -destination "platform=iOS Simulator,name=iPhone 6,OS=9.0" test | xcpretty -c