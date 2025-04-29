#!/bin/bash
set -euo pipefail

PROFILE=${PROFILE:-small}

case "$PROFILE" in
  small)
    export ORA_NUM_VU=5
    export ORA_COUNT_WARE=10
    export ORA_RAMPUP=1
    export ORA_DURATION=2
    export ORA_ALLWAREHOUSE=false
    export HDB_PROFILE_ID=11
    ;;

  medium)
    export ORA_NUM_VU=20
    export ORA_COUNT_WARE=100
    export ORA_RAMPUP=2
    export ORA_DURATION=5
    export ORA_ALLWAREHOUSE=true
    export HDB_PROFILE_ID=12
    ;;

  large)
    export ORA_NUM_VU=80
    export ORA_COUNT_WARE=500
    export ORA_RAMPUP=5
    export ORA_DURATION=10
    export ORA_ALLWAREHOUSE=true
    export HDB_PROFILE_ID=3
    ;;

  scale-run)
    export ORA_COUNT_WARE=500
    export VU_LIST="10 20 40 80 100"
    export ORA_RAMPUP=2
    export ORA_DURATION=20
    export ORA_ALLWAREHOUSE=true
    export HDB_PROFILE_ID=500
    ;;

  *)
    echo "Unknown PROFILE: $PROFILE"
    exit 1
    ;;
esac
