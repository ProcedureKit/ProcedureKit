#!/bin/bash
cat <<-YAML
steps:
-
  name: "Stress Test"
  command: ".ci/scripts/test-stress"
  agents:
    queue: "stress-tests"
    xcode: "$XCODE"
-
  name: "macOS"
  command: ".ci/scripts/test-macos"
  agents:
    xcode: "$XCODE"
-
  name: "iOS"
  command: ".ci/scripts/test-ios"
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"
-
  name: "tvOS"
  command: ".ci/scripts/test-tvos"
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"
YAML

if [[ "$BUILDKITE_BUILD_CREATOR" == "Daniel Thorpe" ]]; then
cat <<-YAML

- wait

- 
  name: "Test CocoaPods Integration"
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

- wait

YAML

if [[ "$BUILDKITE_BUILD_CREATOR" != "Daniel Thorpe" ]]; then
cat <<-YAML

- block: "Docs"

YAML
fi

cat <<-YAML

- 
  name: ":aws: Generate Docs"
  trigger: "procedurekit-documentation"
  build:
    message: "Generating documentation for ProcedureKit"
    commit: "HEAD"
    branch: "master"
    env:
      PROCEDUREKIT_HASH: "$COMMIT"
      PROCEDUREKIT_BRANCH: "$BRANCH"
YAML