#!/bin/bash

set -eu

# Makes sure all the steps run on this same agent
sed "s/\$BUILDKITE_AGENT_META_DATA_NAME/$BUILDKITE_AGENT_META_DATA_NAME/" .buildkite/pipeline.template.yml
