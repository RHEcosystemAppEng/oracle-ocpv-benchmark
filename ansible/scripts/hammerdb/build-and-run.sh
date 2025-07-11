#!/bin/bash
set -euo pipefail

# Load environment variables from .env file
source .env

echo "=================================================="
echo "HammerDB: Build Schema and Run Benchmark"
echo "=================================================="
echo "PROFILE: $PROFILE"
echo "=================================================="

# Step 1: Build the schema
echo "Step 1: Building HammerDB TPCC Schema..."
./build.sh

echo ""
echo "Waiting 10 seconds before starting benchmark..."
sleep 10

# Step 2: Run the benchmark
echo "Step 2: Running HammerDB Benchmark..."
./run.sh

echo "=================================================="
echo "HammerDB build and run completed!"
echo "Results available at: $RESULTS_DIR"
echo "=================================================="