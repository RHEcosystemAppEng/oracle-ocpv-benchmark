#!/bin/bash
set -euo pipefail
set -x

HAMMERDB_VERSION=${HAMMERDB_VERSION:-4.12}
BENCHNAME=${BENCHNAME:-$(date +"%Y-%m-%dT%H:%M:%S")}
PROFILE=${PROFILE:-small}

export TNS_ADMIN=/opt/HammerDB/hammerdb-oracle-tns/

source ./profile.sh

export ORACLE_SYSTEM_PASSWORD=${ORACLE_SYSTEM_PASSWORD:-ChangePassw0rd}
mkdir -p results/

cd /opt/HammerDB/4.12
(time ./hammerdbcli auto ./../benchmark_scripts/run.tcl | tee "./../benchmark_scripts/results/hammerdb_run_${BENCHNAME}.log")

grep -oP '[0-9]+(?= NOPM)' "./../benchmark_scripts/results/hammerdb_run_${BENCHNAME}.log" | tee -a "./../benchmark_scripts/results/hammerdb_nopm_${BENCHNAME}.log"
