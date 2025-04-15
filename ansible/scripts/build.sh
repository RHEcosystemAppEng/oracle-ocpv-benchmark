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

start_time=$(date +%s)

cd ".."
./hammerdbcli auto benchmark_scripts/build.tcl | tee "benchmark_scripts/results/hammerdb_build_${BENCHNAME}.log"

end_time=$(date +%s)
echo "Build completed in $((end_time - start_time)) seconds"
