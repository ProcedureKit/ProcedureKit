#!/bin/bash
cat <<-YAML
steps:
  - name: "ProcedureKit"
    command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane mac test"
    agents:
      xcode: "$XCODE"
YAML

if [[ "$BUILDKITE_BUILD_CREATOR" == "Daniel Thorpe" ]]; then
cat <<-YAML

  - wait

  - name: "Test CocoaPods Integration"
    trigger: "tryprocedurekit"
    build:
      message: "Testing ProcedureKit Integration via Cocoapods"
      commit: "HEAD"
      branch: "cocoapods"
      env:
        PROCEDUREKIT_HASH: "$COMMIT"
YAML
fi