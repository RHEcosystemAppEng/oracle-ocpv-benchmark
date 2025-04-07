#!/bin/bash
set -euo pipefail

HAMMERDB_VERSION=${HAMMERDB_VERSION:-4.12}
isodate=$(date +"%Y-%m-%dT%H:%M:%S")
BENCHNAME=${BENCHNAME:-${isodate}}
export ORACLE_SYSTEM_PASSWORD=<>
mkdir -p results

./install-hammerdb.sh "$HAMMERDB_VERSION"
#./oracle-env.sh
start_time=$(date +%s)

if ! (cd "HammerDB-$HAMMERDB_VERSION" && ./hammerdbcli auto ../build.tcl | tee "../results/hammerdb_build_${BENCHNAME}.log"); then
  echo "HammerDB build failed"
  exit 1
fi

end_time=$(date +%s)
echo "Elapsed: $((end_time - start_time)) seconds"
