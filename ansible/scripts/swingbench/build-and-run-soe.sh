#!/bin/bash
set -euo pipefail

# Source environment variables
source .env

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