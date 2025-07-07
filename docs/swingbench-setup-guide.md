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
├── swingbench/20231104_jdk11/     # SwingBench binaries
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

### Option 1: Separate Steps
```bash
cd /opt/ocpv-benchmark/scripts/swingbench

# Build schema
./build-soe-schema.sh

# Run benchmark
./run-soe-benchmark.sh
```

### Option 2: Combined
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

## Notes

Tests run longer than specified `RUN_TIME` due to ramp-up/down phases. `RUN_TIME=1` typically takes 3-4 minutes total.

Results are saved to `/opt/ocpv-benchmark/scripts/swingbench/results/` with key metrics: TPS, Response Time, Error Rate.

## Troubleshooting

**Connection issues**: `export TNS_ADMIN=/opt/ocpv-benchmark/tns && tnsping <tns_name>`

**Schema conflicts**: `./cleanup-soe-schema.sh`

**Monitor tests**: `tail -f /opt/ocpv-benchmark/scripts/swingbench/results/soe_benchmark_run_*.log` 