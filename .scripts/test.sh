#!/usr/bin/env bash
source /usr/local/opt/chruby/share/chruby/chruby.sh
chruby ruby

bundle update
bundle exec set -o pipefail && xcodebuild -scheme "Operations" -destination "platform=iOS Simulator,name=iPhone 6,OS=9.0" test | xcpretty