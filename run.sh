#!/bin/bash

set -euo pipefail
set -x

HAMMERDB_VERSION=${HAMMERDB_VERSION:-4.12}
BENCHNAME=${BENCHNAME:-$(date +"%Y-%m-%dT%H:%M:%S")}
export ORACLE_SYSTEM_PASSWORD=<>

mkdir -p results/

if [[ ! -d "HammerDB-$HAMMERDB_VERSION" ]]; then
  ./download-hammerdb.sh "$HAMMERDB_VERSION"
fi

# Run the HammerDB TPCC benchmark
(cd "HammerDB-$HAMMERDB_VERSION" && time ./hammerdbcli auto ../run.tcl | tee "../results/hammerdb_run_${BENCHNAME}.log")

# Extract and log the NOPM (New Orders Per Minute) result
grep -oP '[0-9]+(?= NOPM)' "./results/hammerdb_run_${BENCHNAME}.log" | tee -a "./results/hammerdb_nopm_${BENCHNAME}.log"