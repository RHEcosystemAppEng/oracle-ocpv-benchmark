#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables from the same directory as the script
source "$SCRIPT_DIR/.env"

echo "=================================================="
echo "SwingBench SOE: Build Schema and Run Benchmark"
echo "=================================================="

# Step 1: Build the schema
echo "Step 1: Building SOE Schema..."
./build-soe-schema.sh

echo ""
echo "Waiting 10 seconds before starting benchmark..."
sleep 10

# Step 2: Run the benchmark
echo "Step 2: Running SOE Benchmark..."
./run-soe-benchmark.sh

echo "=================================================="
echo "SwingBench SOE build and run completed!"
echo "==================================================" 