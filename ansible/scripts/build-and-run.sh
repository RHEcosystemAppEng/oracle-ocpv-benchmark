#!/bin/bash
set -euo pipefail

PROFILE=${PROFILE:-small}
BENCHNAME=${BENCHNAME:-$(date +"%Y-%m-%dT%H:%M:%S")}
export BENCHNAME

echo "Running build and run with PROFILE=$PROFILE"
./build.sh
./run.sh