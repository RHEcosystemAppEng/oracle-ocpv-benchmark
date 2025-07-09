# SwingBench Setup Guide

SwingBench is an Oracle database benchmark tool that simulates e-commerce workloads (SOE - Sales Order Entry). This guide covers installation, configuration, and execution.

## Installation

Run the SwingBench installation playbook:

```bash
cd ansible
ansible-playbook -i inventory.yaml playbooks/setup-swingbench/install_setup_swingbench.yml
```

This creates the following directory structure:
```
/opt/ocpv-benchmark/
├── swingbench/25052023_jdk11/     # SwingBench binaries (May 2023 - stable)
├── scripts/swingbench/            # Test scripts and .env
├── scripts/swingbench/results/    # Test results
└── tns/                           # TNS configuration
```

## Configuration

SSH to your VM and configure the environment:

```bash
cd /opt/ocpv-benchmark/scripts/swingbench
vi .env
```

Update these required variables:
```bash
export ORACLE_SYSTEM_PASSWORD=your_system_password
export ORACLE_SYS_PASSWORD=your_sys_password
export USER_COUNT=4      # Concurrent users
export RUN_TIME=2        # Runtime in minutes
export SCALE_FACTOR=1    # Schema size multiplier
```

## Running Tests

### Option 1: Quick Verification Test
```bash
cd /opt/ocpv-benchmark/scripts/swingbench

# Quick 30-second test to verify installation
./simple-swingbench-test.sh
```

### Option 2: Separate Steps
```bash
cd /opt/ocpv-benchmark/scripts/swingbench

# Build schema
./build-soe-schema.sh

# Run benchmark
./run-soe-benchmark.sh
```

### Option 3: Combined Workflow
```bash
cd /opt/ocpv-benchmark/scripts/swingbench
./build-and-run-soe.sh
```

### Custom Parameters
```bash
# Quick test
export USER_COUNT=2 RUN_TIME=1
./run-soe-benchmark.sh

# Load test
export USER_COUNT=16 RUN_TIME=5
./run-soe-benchmark.sh

# Large schema
export SCALE_FACTOR=5
./build-soe-schema.sh
```

## Available Scripts

- **`simple-swingbench-test.sh`**: Quick 30-second benchmark to verify SwingBench installation and SOE schema functionality
- **`build-soe-schema.sh`**: Creates a fresh SOE (Sales Order Entry) schema for benchmarking using command line parameters
- **`run-soe-benchmark.sh`**: Runs a configurable benchmark against the SOE schema
- **`cleanup-soe-schema.sh`**: Removes the SOE schema and related objects
- **`build-and-run-soe.sh`**: Automated workflow that builds schema and runs benchmark

## Results

All benchmark results are saved to `/opt/ocpv-benchmark/scripts/swingbench/results/` with timestamped filenames:

### Test Results Files
- **`swingbench_simple_test.log`**: Simple test output
- **`swingbench_results_YYYYMMDD_HHMMSS.xml`**: Simple test XML results
- **`swingbench_latest_results.xml`**: Symlink to latest simple test results

### Schema Build Results
- **`soe_schema_build_YYYYMMDD_HHMMSS.log`**: Schema build logs
- **`soe_schema_test_YYYYMMDD_HHMMSS.xml`**: Schema verification test XML results

### Benchmark Results
- **`soe_benchmark_run_YYYYMMDD_HHMMSS.log`**: Benchmark run logs
- **`soe_results_YYYYMMDD_HHMMSS.xml`**: XML results with detailed metrics
- **`soe_results_YYYYMMDD_HHMMSS.csv`**: CSV results with key metrics (TPS, Response Time, Error Rate)

## Notes

Tests run longer than specified `RUN_TIME` due to ramp-up/down phases. `RUN_TIME=1` typically takes 3-4 minutes total.

## Troubleshooting

**Connection issues**: `export TNS_ADMIN=/opt/ocpv-benchmark/tns && tnsping <tns_name>`

**Schema conflicts**: `./cleanup-soe-schema.sh`

**Monitor tests**: `tail -f /opt/ocpv-benchmark/scripts/swingbench/results/soe_benchmark_run_*.log`

**Schema creation**: Scripts use command line parameters to create schemas directly with oewizard (no config files needed)

**Results location**: All XML results are automatically saved to the results directory with timestamped filenames

**Java version**: Ensure Java 11 is installed: `java -version` 