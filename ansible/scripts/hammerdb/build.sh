#!/bin/bash
set -euo pipefail

# Load environment variables from .env file
source .env

# Load profile settings
source ./profile.sh

mkdir -p "$RESULTS_DIR"

# dropping the tpcc schema before test run. and ignore the error.
if [ "$DROP_TPCC_SCHEMA_FOR_EACH_BENCHMARK" = "true" ]; then
  echo "Before starting the benchmark...deleting the oracle user tpcc."
  ./drop_tpcc_user.sh || echo "Ignoring failure in drop_tpcc_user.sh"
fi

start_time=$(date +%s)

echo "=============================="
echo "HammerDB Schema Build Starting"
echo "=============================="
echo "WAREHOUSES:      $ORA_COUNT_WARE"
echo "HAMMERDB_HOME:   $HAMMERDB_HOME"
echo "RESULTS_DIR:     $RESULTS_DIR"
echo "=============================="

cd "$HAMMERDB_HOME"
./hammerdbcli auto "$HAMMERDB_SCRIPTS/build.tcl" | tee "$RESULTS_DIR/hammerdb_build_${BENCHNAME}.log"

end_time=$(date +%s)
echo "✅ Build completed in $((end_time - start_time)) seconds"
