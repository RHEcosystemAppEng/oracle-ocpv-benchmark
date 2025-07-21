#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Store any pre-set values that might be overridden by scaling scripts  
PRESET_USER_COUNT="${USER_COUNT:-}"
PRESET_BENCHMARK_NAME="${BENCHMARK_NAME:-}"
PRESET_SCALE_FACTOR="${SCALE_FACTOR:-}"

# Source environment variables from the same directory as the script
source "$SCRIPT_DIR/.env"

# Restore any pre-set values (scaling script overrides take precedence)
if [ -n "$PRESET_USER_COUNT" ]; then
    export USER_COUNT="$PRESET_USER_COUNT"
fi
if [ -n "$PRESET_BENCHMARK_NAME" ]; then
    export BENCHMARK_NAME="$PRESET_BENCHMARK_NAME"
fi
if [ -n "$PRESET_SCALE_FACTOR" ]; then
    export SCALE_FACTOR="$PRESET_SCALE_FACTOR"
fi

echo "=================================================="
echo "SwingBench SOE: Build Schema and Run Benchmark"
echo "=================================================="

# Step 1: Conditionally build the schema
if [ "${DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK:-false}" = "true" ]; then
    echo "Step 1: Building SOE Schema (DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=true)..."
    ./build-soe-schema.sh
else
    echo "Step 1: Skipping SOE Schema build (DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=false)..."
    echo "⚠️  Using existing SOE schema - ensure it exists and is properly configured"
    
    # Quick check if SOE user exists
    echo "Checking if SOE user exists..."
    echo "exit" | sqlplus -S "$SOE_USER/$SOE_PASSWORD@$ORACLE_SID" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Cannot connect as SOE user. Schema may not exist or credentials are wrong."
        echo "💡 Either create the SOE schema manually or set DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=true"
        exit 1
    fi
    echo "✅ SOE user connection successful - proceeding with existing schema"
fi

echo ""
echo "Waiting 10 seconds before starting benchmark..."
sleep 10

# Step 2: Run the benchmark
echo "Step 2: Running SOE Benchmark..."
./run-soe-benchmark.sh

echo "=================================================="
echo "SwingBench SOE build and run completed!"
echo "==================================================" 