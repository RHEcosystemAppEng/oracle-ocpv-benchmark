#!/bin/bash
set -euo pipefail
set -x

source ./profile.sh

# Load environment variables only once from .env if it exists
source ./load-env.sh


mkdir -p results/

TCL_SCRIPT=run.tcl
if [[ "$PROFILE" == "scale-run" ]]; then
  TCL_SCRIPT=scalerun.tcl
fi

cd /opt/HammerDB/$HAMMERDB_VERSION
(time ./hammerdbcli auto ./../benchmark_scripts/$TCL_SCRIPT | tee "./../benchmark_scripts/results/hammerdb_run_${BENCHNAME}.log")

grep -oP '[0-9]+(?= NOPM)' "./../benchmark_scripts/results/hammerdb_run_${BENCHNAME}.log" | tee -a "./../benchmark_scripts/results/hammerdb_nopm_${BENCHNAME}.log"
