#!/bin/bash
set -euo pipefail

# Load environment variables from .env if it exists
if [[ -f ".env" ]]; then
  set -a
  source .env
  set +a
fi

source ./profile.sh

mkdir -p results

# dropping the tpcc schema before test run. and ignore the error.
echo "Before starting the benchmark...deleting the oracle user tpcc."
./drop_tpcc_user.sh || echo "Ignoring failure in drop_tpcc_user.sh"

start_time=$(date +%s)

cd "./../4.12"
./hammerdbcli auto ./../benchmark_scripts/build.tcl | tee "./../benchmark_scripts/results/hammerdb_build_${BENCHNAME}.log"

end_time=$(date +%s)
echo "Build completed in $((end_time - start_time)) seconds"
