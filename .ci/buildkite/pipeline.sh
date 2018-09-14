#!/bin/bash
cat <<-YAML
steps:
-
  name: "Stress Test"
  command: ".ci/scripts/test-stress"
  retry:
    automatic: true
  artifact_paths:
    - ".ci/results/xcodebuild.log"
  agents:
    queue: "stress-tests"
    xcode: "$XCODE"
-
  name: "macOS"
  command: ".ci/scripts/test-macos"
  retry:
    automatic: true
  artifact_paths:
    - ".ci/results/xcodebuild.log"
  agents:
    xcode: "$XCODE"
-
  name: "iOS"
  command: ".ci/scripts/test-ios"
  retry:
    automatic: true
  artifact_paths:
    - ".ci/results/xcodebuild.log"
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"
-
  name: "tvOS"
  command: ".ci/scripts/test-tvos"
  retry:
    automatic: true
  artifact_paths:
    - ".ci/results/xcodebuild.log"
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"
    
- wait

- 
  name: "Test CocoaPods Integration"
  command: ".ci/scripts/test-cocoapods"  
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"
YAML

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