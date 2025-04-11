#!/bin/bash

PROFILE=${PROFILE:-small}

case "$PROFILE" in
  small)
    export ORA_NUM_VU=5
    export ORA_COUNT_WARE=10
    export ORA_RAMPUP=1
    export ORA_DURATION=2
    export ORA_ALLWAREHOUSE=false
    ;;
  medium)
    export ORA_NUM_VU=20
    export ORA_COUNT_WARE=100
    export ORA_RAMPUP=2
    export ORA_DURATION=5
    export ORA_ALLWAREHOUSE=true
    ;;
  large)
    export ORA_NUM_VU=80
    export ORA_COUNT_WARE=1000
    export ORA_RAMPUP=5
    export ORA_DURATION=20
    export ORA_ALLWAREHOUSE=true
    ;;
  *)
    echo "Unknown PROFILE: $PROFILE"
    exit 1
    ;;
esac
