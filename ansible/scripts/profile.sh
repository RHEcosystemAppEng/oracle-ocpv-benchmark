#!/bin/bash
set -euo pipefail

PROFILE=${PROFILE:-small}

case "$PROFILE" in
  small)
    # Quick validation test - minimal resource usage
    export ORA_NUM_VU=5
    export ORA_COUNT_WARE=10
    export ORA_RAMPUP=2
    export ORA_DURATION=5
    export ORA_ALLWAREHOUSE=false
    export HDB_PROFILE_ID=100
    echo "Small profile: Quick validation test (7 min total)"
    ;;

  medium)
    # Development/testing workload - moderate resource usage
    export ORA_NUM_VU=20
    export ORA_COUNT_WARE=100
    export ORA_RAMPUP=3
    export ORA_DURATION=10
    export ORA_ALLWAREHOUSE=true
    export HDB_PROFILE_ID=200
    echo "Medium profile: Development testing (13 min total)"
    ;;

  large)
    # Production-like workload - high resource usage
    export ORA_NUM_VU=80
    export ORA_COUNT_WARE=500
    export ORA_RAMPUP=5
    export ORA_DURATION=15
    export ORA_ALLWAREHOUSE=true
    export HDB_PROFILE_ID=300
    echo "Large profile: Production-like load (20 min total)"
    ;;

  xlarge)
    # High-intensity stress test - maximum realistic load
    export ORA_NUM_VU=120
    export ORA_COUNT_WARE=1000
    export ORA_RAMPUP=5
    export ORA_DURATION=20
    export ORA_ALLWAREHOUSE=false
    export HDB_PROFILE_ID=4              # Logical sequence for XL profile
    echo "XLarge profile: High-intensity stress test (25 min total)"
    ;;

  scale-run)
    # Multi-VU scaling test - for capacity planning
    export ORA_COUNT_WARE=500
    export VU_LIST="20 40 60 80 100"       # More granular scaling steps
    export ORA_RAMPUP=3                    # Faster rampup for multiple runs
    export ORA_DURATION=20                 # Shorter duration for multiple tests
    export ORA_ALLWAREHOUSE=false           # Essential for scaling tests
    export HDB_PROFILE_ID=5              # Logical sequence for scale-run profile
    echo "Scale-run profile: Multi-VU capacity planning"
    ;;

  quick)
    # Ultra-fast smoke test - minimal validation
    export ORA_NUM_VU=3
    export ORA_COUNT_WARE=5
    export ORA_RAMPUP=1
    export ORA_DURATION=3
    export ORA_ALLWAREHOUSE=true
    export HDB_PROFILE_ID=1
    echo "Quick profile: Ultra-fast smoke test (4 min total)"
    ;;

  endurance)
    # Long-running stability test
    export ORA_NUM_VU=40
    export ORA_COUNT_WARE=200
    export ORA_RAMPUP=5
    export ORA_DURATION=60                 # 1-hour test
    export ORA_ALLWAREHOUSE=false
    export HDB_PROFILE_ID=6              # Logical sequence for endurance profile
    echo "Endurance profile: Long-running stability test (65 min total)"
    ;;

  *)
    echo "Unknown PROFILE: $PROFILE"
    echo "Available profiles: small, medium, large, xlarge, scale-run, quick, endurance"
    exit 1
    ;;
esac

# Display configuration
echo "Configuration for $PROFILE profile:"
echo "  Virtual Users: ${ORA_NUM_VU:-N/A}"
echo "  Warehouses: $ORA_COUNT_WARE"
echo "  Rampup: $ORA_RAMPUP minutes"
echo "  Duration: $ORA_DURATION minutes"
echo "  All Warehouse: $ORA_ALLWAREHOUSE"
echo "  Profile ID: $HDB_PROFILE_ID"
if [[ -n "${VU_LIST:-}" ]]; then
    echo "  VU Scale List: $VU_LIST"
fi
echo ""
