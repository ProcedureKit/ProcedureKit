#!/usr/bin/env bash
source /usr/local/opt/chruby/share/chruby/chruby.sh
chruby ruby
bundle update && bundle exec fastlane test
bash <(curl -s https://codecov.io/bash) -D .fastlane/xcodebuild-data
