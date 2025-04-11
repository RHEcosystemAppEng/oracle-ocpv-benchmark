#!/bin/bash
set -euo pipefail

HAMMERDB_VERSION=${HAMMERDB_VERSION:-4.12}
BENCHNAME=${BENCHNAME:-$(date +"%Y-%m-%dT%H:%M:%S")}
PROFILE=${PROFILE:-small}

source ./profile.sh

export ORACLE_SYSTEM_PASSWORD=<>

export ORA_TPCC_USER=${ORA_TPCC_USER:-tpcc}
export ORA_TPCC_PASS=${ORA_TPCC_PASS:-tpcc}
export ORACLE_INSTANCE=${ORACLE_INSTANCE:-oralab}
export ORA_TABLESPACE=${ORA_TABLESPACE:-USERS}
export ORA_STORAGE=${ORA_STORAGE:-DEFAULT}
export ORA_DURABILITY=${ORA_DURABILITY:-nologging}

mkdir -p results

./install-hammerdb.sh "$HAMMERDB_VERSION"

start_time=$(date +%s)

cd "HammerDB-$HAMMERDB_VERSION"
./hammerdbcli auto ../build.tcl | tee "../results/hammerdb_build_${BENCHNAME}.log"

end_time=$(date +%s)
echo "Build completed in $((end_time - start_time)) seconds"
