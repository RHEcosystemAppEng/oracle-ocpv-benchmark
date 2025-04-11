#!/bin/bash
set -euo pipefail
set -x

HAMMERDB_VERSION=${HAMMERDB_VERSION:-4.12}
BENCHNAME=${BENCHNAME:-$(date +"%Y-%m-%dT%H:%M:%S")}
PROFILE=${PROFILE:-small}

source ./profile.sh

export ORACLE_SYSTEM_PASSWORD=<>
mkdir -p results/

(cd "HammerDB-$HAMMERDB_VERSION" && time ./hammerdbcli auto ../run.tcl | tee "../results/hammerdb_run_${BENCHNAME}.log")

grep -oP '[0-9]+(?= NOPM)' "./results/hammerdb_run_${BENCHNAME}.log" | tee -a "./results/hammerdb_nopm_${BENCHNAME}.log"
