#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables from the same directory as the script
source "$SCRIPT_DIR/.env"

echo "=================================================="
echo "SwingBench SOE Schema Cleanup"
echo "=================================================="

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Log file for cleanup
CLEANUP_LOG="$RESULTS_DIR/soe_schema_cleanup_${BENCHMARK_NAME}.log"

echo "Cleanup log: $CLEANUP_LOG"
echo "Starting SOE schema cleanup at $(date)" | tee "$CLEANUP_LOG"

cd "$SWINGBENCH_HOME/bin"

# Drop SOE schema using oewizard (using SYS as SYSDBA for required privileges)
echo "Dropping SOE schema..." | tee -a "$CLEANUP_LOG"

./oewizard \
  -dba "sys as sysdba" \
  -dbap "$ORACLE_SYS_PASSWORD" \
  -u "$SOE_USER" \
  -p "$SOE_PASSWORD" \
  -cs "$ORACLE_SID" \
  -dt thin \
  -drop \
  -cl 2>&1 | tee -a "$CLEANUP_LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ SOE schema cleanup completed successfully at $(date)" | tee -a "$CLEANUP_LOG"
else
    echo "⚠️  SOE schema cleanup may have failed, but continuing..." | tee -a "$CLEANUP_LOG"
    # Don't exit with error for cleanup failures
fi

echo "=================================================="
echo "Cleanup completed. Log file: $CLEANUP_LOG"
echo "==================================================" 