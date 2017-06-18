#!/bin/bash
cat <<-YAML
steps:
  -
    name: "ProcedureKit"
    command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane mac test"
    agents:
      xcode: "$XCODE"
YAML
