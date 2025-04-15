#!/bin/bash
set -euo pipefail

PROFILE=${PROFILE:-small}
BENCHNAME=${BENCHNAME:-$(date +"%Y-%m-%dT%H:%M:%S")}
export BENCHNAME

# dropping the tpcc schema before test run. and ignore the error.
echo "Before starting the benchmark...deleting the oracle user tpcc."
./drop_tpcc_user.sh || echo "Ignoring failure in drop_tpcc_user.sh"

echo "Running build and run with PROFILE=$PROFILE"
./build.sh
./run.sh