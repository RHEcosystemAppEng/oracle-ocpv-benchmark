#!/bin/bash
set -euo pipefail

# Source environment variables
source .env

echo "=================================================="
echo "SwingBench SOE Schema Build Starting"
echo "=================================================="
echo "Scale Factor: $SCALE_FACTOR"
echo "TNS Admin: $TNS_ADMIN"
echo "Oracle SID: $ORACLE_SID"
echo "=================================================="

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Log file for this build
BUILD_LOG="$RESULTS_DIR/soe_schema_build_${BENCHMARK_NAME}.log"

echo "Build log: $BUILD_LOG"
echo "Starting SOE schema build at $(date)" | tee "$BUILD_LOG"

# Build SOE schema using oewizard
echo "Building SOE schema..." | tee -a "$BUILD_LOG"

cd "$SWINGBENCH_HOME/bin"

# Use oewizard to create the SOE schema (using SYS as SYSDBA for required privileges)
./oewizard \
  -dba "sys as sysdba" \
  -dbap "$ORACLE_SYS_PASSWORD" \
  -u "$SOE_USER" \
  -p "$SOE_PASSWORD" \
  -cs "$ORACLE_SID" \
  -dt thin \
  -create \
  -scale "$SCALE_FACTOR" \
  -cl 2>&1 | tee -a "$BUILD_LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ SOE schema build completed successfully at $(date)" | tee -a "$BUILD_LOG"
    echo "Schema: $SOE_USER/$SOE_PASSWORD"
    echo "Scale Factor: $SCALE_FACTOR"
else
    echo "❌ SOE schema build failed at $(date)" | tee -a "$BUILD_LOG"
    exit 1
fi

echo "=================================================="
echo "Build completed. Log file: $BUILD_LOG"
echo "==================================================" 