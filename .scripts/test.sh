#!/usr/bin/env bash
source /usr/local/opt/chruby/share/chruby/chruby.sh
chruby ruby

bundle update
bundle exec set -o pipefail && xcodebuild -project "framework/Operations.xcodeproj" -scheme "Operations" -destination "platform=iOS Simulator,name=iPhone 6,OS=8.4" test | xcpretty -c