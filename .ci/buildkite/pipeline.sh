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

cat <<-YAML
  - block: ":aws: Generate Documentation"
    branches: "master development release/*"

  - name: ":aws: Generate Documentation"
    trigger: "procedurekit-documentation"
    build:
      message: "Generating documentation for ProcedureKit"
      commit: "HEAD"
      branch: "setup"
      env:
        PROCEDUREKIT_HASH: "$COMMIT"
        PROCEDUREKIT_BRANCH: "$BRANCH"        

YAML