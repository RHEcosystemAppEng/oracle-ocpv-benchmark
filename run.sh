#!/bin/bash
set -euo pipefail
set -x

HAMMERDB_VERSION=${HAMMERDB_VERSION:-4.12}
BENCHNAME=${BENCHNAME:-$(date +"%Y-%m-%dT%H:%M:%S")}
PROFILE=${PROFILE:-small}

source ./profile.sh

export ORACLE_SYSTEM_PASSWORD=Chang4On

export ORA_TPCC_USER=${ORA_TPCC_USER:-tpcc}
export ORA_TPCC_PASS=${ORA_TPCC_PASS:-tpcc}
export ORACLE_INSTANCE=${EORACL_INSTANCE:-oralab}
export ORA_TABLESPACE=${ORA_TABLESPACE:-USERS}
export ORA_STORAGE=${ORA_STORAGE:-DEFAULT}
export ORA_DURABILITY=${ORA_DURABILITY:-nologging}


mkdir -p results/

TCL_SCRIPT=run.tcl
if [[ "$PROFILE" == "scale-run" ]]; then
  TCL_SCRIPT=scalerun.tcl
fi

(cd "HammerDB-$HAMMERDB_VERSION" && time ./hammerdbcli auto ../$TCL_SCRIPT | tee "../results/hammerdb_run_${BENCHNAME}.log")

grep -oP '[0-9]+(?= NOPM)' "./results/hammerdb_run_${BENCHNAME}.log" | tee -a "./results/hammerdb_nopm_${BENCHNAME}.log"
