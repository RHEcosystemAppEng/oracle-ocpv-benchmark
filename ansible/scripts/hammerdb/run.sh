#!/bin/bash
set -euo pipefail

# Load environment variables from .env file
source .env

# Load profile settings
source ./profile.sh

mkdir -p "$RESULTS_DIR"

TCL_SCRIPT=run.tcl
if [[ "$PROFILE" == "scale-run" ]]; then
  TCL_SCRIPT=scalerun.tcl
fi

echo "=============================="
echo "HammerDB Benchmark Starting"
echo "=============================="
echo "PROFILE:         $PROFILE"
echo "TCL_SCRIPT:      $TCL_SCRIPT"
echo "WAREHOUSES:      $ORA_COUNT_WARE"
echo "THREADS:         $ORA_NUM_THREADS"
echo "DURATION:        $ORA_MINUTES_DURATION minutes"
echo "HAMMERDB_HOME:   $HAMMERDB_HOME"
echo "RESULTS_DIR:     $RESULTS_DIR"
echo "=============================="

cd "$HAMMERDB_HOME"
(time ./hammerdbcli auto "$HAMMERDB_SCRIPTS/$TCL_SCRIPT" | tee "$RESULTS_DIR/hammerdb_run_${BENCHNAME}.log")

echo "Extracting NOPM results..."
grep -oP '[0-9]+(?= NOPM)' "$RESULTS_DIR/hammerdb_run_${BENCHNAME}.log" | tee -a "$RESULTS_DIR/hammerdb_nopm_${BENCHNAME}.log"

echo "✅ Benchmark completed. Results available at: $RESULTS_DIR"
