#!/bin/bash
set -euo pipefail

source ./profile.sh

# Load environment variables only once from .env if it exists
source ./load-env.sh

mkdir -p results


start_time=$(date +%s)

echo "-----------------------------"
echo "WAREHOUSES:      $ORA_COUNT_WARE"
echo "ORA_NUM_VU:      ORA_NUM_VU"


echo "-----------------------------"

cd "./../$HAMMERDB_VERSION"
./hammerdbcli auto ./../benchmark_scripts/build.tcl | tee "./../benchmark_scripts/results/hammerdb_build_${BENCHNAME}.log"

end_time=$(date +%s)
echo "Build completed in $((end_time - start_time)) seconds"
