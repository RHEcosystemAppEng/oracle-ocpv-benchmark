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

# Schema Management (optional)
export DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=false   # true=rebuild schema, false=reuse existing (default)
```

## Schema Management

SwingBench supports conditional schema rebuilding via the `DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK` environment variable:

### Reuse Existing Schema (Default)
```bash
export DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=false
```
- **Behavior**: Uses existing SOE schema without rebuilding
- **Use case**: Preserve existing data, faster test execution, custom schema modifications
- **Requirement**: SOE schema must already exist and be accessible

### Rebuild Schema
```bash
export DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=true
```
- **Behavior**: Drops and recreates SOE schema before each test
- **Use case**: Consistent testing with fresh data, performance baselines
- **⚠️ Warning**: Destroys existing SOE schema and all data

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

### Option 4: Scaling User Count Test
```bash
cd /opt/ocpv-benchmark/scripts/swingbench

# Run benchmarks with increasing user counts: 20, 40, 60, 80, 100
# Each test includes: 1-minute ramp-up + configured runtime + 2-minute recovery
./scale-users-soe-benchmark.sh
```

### Custom Parameters
```bash
# Quick test using existing schema (default - faster)
export USER_COUNT=2 RUN_TIME=1
./run-soe-benchmark.sh

# Load test with schema rebuild (clean slate)
export USER_COUNT=16 RUN_TIME=5 DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=true
./build-and-run-soe.sh

# Large schema (rebuild required for size change)
export SCALE_FACTOR=5 DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=true
./build-soe-schema.sh

# Scaling test using existing schema (default - preserves data)
./scale-users-soe-benchmark.sh

# Scaling test with fresh schema rebuild
export DROP_SOE_SCHEMA_FOR_EACH_BENCHMARK=true
./scale-users-soe-benchmark.sh
```

## Available Scripts

- **`simple-swingbench-test.sh`**: Quick 30-second benchmark to verify SwingBench installation and SOE schema functionality
- **`build-soe-schema.sh`**: Creates a fresh SOE (Sales Order Entry) schema for benchmarking using command line parameters
- **`run-soe-benchmark.sh`**: Runs a configurable benchmark against the SOE schema
- **`cleanup-soe-schema.sh`**: Removes the SOE schema and related objects
- **`build-and-run-soe.sh`**: Automated workflow that builds schema and runs benchmark
- **`scale-users-soe-benchmark.sh`**: Performance scaling test that runs benchmarks with 20, 40, 60, 80, and 100 concurrent users (includes 1-minute ramp-up per test and 2-minute recovery between tests)

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

### Scaling Test Results
- **`scale_20users_YYYYMMDD_HHMMSS.*`**: Results for 20 concurrent users
- **`scale_40users_YYYYMMDD_HHMMSS.*`**: Results for 40 concurrent users
- **`scale_60users_YYYYMMDD_HHMMSS.*`**: Results for 60 concurrent users
- **`scale_80users_YYYYMMDD_HHMMSS.*`**: Results for 80 concurrent users
- **`scale_100users_YYYYMMDD_HHMMSS.*`**: Results for 100 concurrent users
- **`scaling_summary_YYYYMMDD_HHMMSS.txt`**: Consolidated tabular report (shareable format)

## Scaling Test Reporting

The scaling script provides comprehensive reporting at completion:

### Console Output
```
SCALING BENCHMARK RESULTS SUMMARY
========================================================
Users      | TPS      | Avg Resp(ms) | Errors   | Throughput | Status  
-----------|----------|--------------|----------|------------|--------
20         | 245.6    | 81.2         | 0        | 14736      | ✅ OK   
40         | 478.3    | 83.7         | 0        | 28698      | ✅ OK   
60         | 612.4    | 97.9         | 2        | 36744      | ⚠️ WARN  
80         | 698.1    | 114.5        | 0        | 41886      | ✅ OK   
100        | 721.8    | 138.6        | 0        | 43308      | ✅ OK   
========================================================

PERFORMANCE ANALYSIS
========================================================
✅ Tests completed: 5/5
🏆 Best performance: 721.8 TPS with 100 users

📝 Shareable report saved to: scaling_summary_20240715_143022.txt
```

### Shareable Text Report
- Automatically generated in plain text format
- Copy-pasteable for emails, reports, documentation
- Includes test configuration, results table, and analysis
- Saved to results directory with timestamp

## Notes

Tests run longer than specified `RUN_TIME` due to ramp-up/down phases. Each test includes:
- **1 minute ramp-up**: Users connect and workload stabilizes (statistics recording starts after ramp-up)
- **Configured runtime**: Actual benchmark measurement period
- **~30 seconds ramp-down**: Users disconnect gracefully

`RUN_TIME=1` typically takes ~2.5 minutes total. Scaling tests include additional 2-minute recovery periods between runs.

## Troubleshooting

**Connection issues**: `export TNS_ADMIN=/opt/ocpv-benchmark/tns && tnsping <tns_name>`

**Schema conflicts**: `./cleanup-soe-schema.sh`

**Monitor tests**: `tail -f /opt/ocpv-benchmark/scripts/swingbench/results/soe_benchmark_run_*.log`

**Schema creation**: Scripts use command line parameters to create schemas directly with oewizard (no config files needed)

**Results location**: All XML results are automatically saved to the results directory with timestamped filenames

**Java version**: Ensure Java 11 is installed: `java -version` 