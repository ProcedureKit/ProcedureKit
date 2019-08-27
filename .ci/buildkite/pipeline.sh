#!/bin/bash
cat <<-YAML

steps:

  - name: ":aws: Generate Docs"
    trigger: "procedurekit-documentation"
    build:
      message: "Generating documentation for ProcedureKit"
      commit: "HEAD"
      branch: "master"
      env:
        PROCEDUREKIT_HASH: "$COMMIT"
        PROCEDUREKIT_BRANCH: "$BRANCH"
YAML