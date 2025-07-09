# OCPV Benchmark Directory Structure

This document describes the organized directory structure for the Oracle Cloud Platform Virtualization (OCPV) benchmark project.

## Overview

All benchmark tools and related components are organized under a single parent directory: `/opt/ocpv-benchmark`

This structure provides:
- **Clear separation** of different benchmark tools
- **Centralized configuration** and results management  
- **Consistent organization** across all components
- **Easy maintenance** and troubleshooting

## Directory Hierarchy

```
/opt/ocpv-benchmark/
├── hammerdb/                       # HammerDB Installation Directory
│   └── 4.12/                      # HammerDB version directory
│       ├── agent/                 # HammerDB agent components
│       ├── bin/                   # HammerDB executables
│       ├── config/                # HammerDB configuration files
│       ├── images/                # HammerDB images and resources
│       ├── include/               # HammerDB include files
│       ├── lib/                   # HammerDB libraries
│       ├── modules/               # HammerDB modules
│       ├── scripts/               # HammerDB built-in scripts
│       └── src/                   # HammerDB source code
│
├── swingbench/                     # SwingBench Installation Directory
│   └── 25052023_jdk11/            # SwingBench version directory (May 2023 - stable)
│       ├── bin/                   # SwingBench executables (oewizard, charbench)
│       ├── configs/               # SwingBench configuration files
│       ├── wizardconfigs/         # SwingBench wizard configurations
│       ├── lib/                   # SwingBench libraries
│       └── sql/                   # SwingBench SQL scripts
│
├── scripts/                        # Benchmark Scripts Directory
│   ├── hammerdb/                  # HammerDB benchmark scripts
│   │   ├── .env                   # HammerDB environment configuration
│   │   ├── build.sh               # Build TPCC schema
│   │   ├── run.sh                 # Run HammerDB benchmark
│   │   ├── build-and-run.sh       # Combined build and run
│   │   ├── build.tcl              # TCL script for schema creation
│   │   ├── run.tcl                # TCL script for benchmark execution
│   │   ├── scalerun.tcl           # TCL script for scale testing
│   │   ├── profile.sh             # Profile configuration script
│   │   ├── load-env.sh            # Environment loading script
│   │   ├── drop_tpcc_user.sh      # TPCC user cleanup script
│   │   ├── create-csv-result.sh   # CSV result generation
│   │   ├── generate_awr_html_report.sh # AWR report generation
│   │   ├── awr_reports/           # AWR report templates directory
│   │   └── results/               # HammerDB benchmark results
│   │       ├── hammerdb_build_*.log   # Schema build logs
│   │       ├── hammerdb_run_*.log     # Benchmark run logs
│   │       ├── hammerdb_nopm_*.log    # NOPM metrics logs
│   │       └── *.csv                  # CSV result files
│   │
│   └── swingbench/                # SwingBench benchmark scripts
│       ├── .env                   # SwingBench environment configuration
│       ├── simple-swingbench-test.sh  # Quick 30-second verification test
│       ├── build-soe-schema.sh    # Build SOE schema
│       ├── run-soe-benchmark.sh   # Run SOE benchmark
│       ├── build-and-run-soe.sh   # Combined build and run
│       ├── cleanup-soe-schema.sh  # SOE schema cleanup
│       └── results/               # SwingBench benchmark results
│           ├── swingbench_simple_test.log # Simple test results
│           ├── soe_schema_build_*.log # SOE schema build logs
│           ├── soe_benchmark_run_*.log# SOE benchmark run logs
│           ├── soe_results_*.xml      # XML result files
│           ├── soe_results_*.csv      # CSV result files
│           └── soe_schema_cleanup_*.log # Schema cleanup logs
│
└── tns/                            # TNS Configuration Directory
    └── tnsnames.ora               # Oracle TNS names configuration
```

## Key Benefits of This Structure

### 1. **Organized Installation Paths**
- Each benchmark tool has its dedicated installation directory
- Version-specific installations are clearly separated using meaningful version identifiers
- No conflicts between different tools

### 2. **Centralized Script Management**
- All custom scripts are organized by tool type
- Environment configurations are co-located with scripts
- Easy to locate and maintain scripts

### 3. **Co-located Results Management**
- Benchmark results are stored within each tool's scripts directory
- Results are easily accessible alongside their respective scripts
- Each tool manages its own results independently

### 4. **Shared Configuration**
- TNS configuration is shared across all tools
- Common environment variables are consistently applied
- Single point of configuration management

## Environment Variables

Each tool maintains its own environment configuration:

### HammerDB Environment (`.env`)
```bash
# HammerDB Installation Path
HAMMERDB_HOME=/opt/ocpv-benchmark/hammerdb/4.12

# HammerDB Scripts Directory
HAMMERDB_SCRIPTS=/opt/ocpv-benchmark/scripts/hammerdb

# Results Directory (relative to scripts directory)
RESULTS_DIR=./results

# Oracle Connection Details
ORACLE_SERVICE_NAME=your_oracle_service
ORACLE_HOST=your_oracle_host
ORACLE_PORT=1521
```

### SwingBench Environment (`.env`) 
```bash
# SwingBench Installation Path
SWINGBENCH_HOME=/opt/ocpv-benchmark/swingbench/25052023_jdk11

# SwingBench Scripts Directory
SWINGBENCH_SCRIPTS=/opt/ocpv-benchmark/scripts/swingbench

# Results Directory
RESULTS_DIR=/opt/ocpv-benchmark/scripts/swingbench/results

# Oracle Connection Details
ORACLE_SID=ORALAB_STANDALONE
TNS_ADMIN=/opt/ocpv-benchmark/tns

# Database Users
SOE_USER=soe
SOE_PASSWORD=Chang4On

# Benchmark Parameters
SCALE_FACTOR=1
USER_COUNT=4
RUN_TIME=1

# Benchmark Naming
BENCHMARK_NAME=$(date +%Y%m%d_%H%M%S)
```

### Shared Environment Variables
```bash
# TNS Configuration Directory
TNS_ADMIN=/opt/ocpv-benchmark/tns

# Oracle Client Installation
ORACLE_HOME=/usr/lib/oracle/19.26/client64
LD_LIBRARY_PATH=/usr/lib/oracle/19.26/client64/lib

# Base Benchmark Directory
BENCHMARK_BASE_PATH=/opt/ocpv-benchmark
```

## Usage Patterns

### HammerDB Usage
```bash
cd /opt/ocpv-benchmark/scripts/hammerdb
vi .env                    # Configure environment
./build-and-run.sh         # Run benchmark
ls results/                # View results
```

### SwingBench Usage  
```bash
cd /opt/ocpv-benchmark/scripts/swingbench

# Quick verification test (30 seconds)
./simple-swingbench-test.sh

# Full workflow (build schema + run benchmark)
./build-and-run-soe.sh

# Individual operations
./build-soe-schema.sh      # Create SOE schema
./run-soe-benchmark.sh     # Run full benchmark
./cleanup-soe-schema.sh    # Clean up schema

# View results
ls results/                # View all results
cat results/soe_results_*.csv  # View CSV results
```

### SwingBench Script Descriptions
- **`simple-swingbench-test.sh`**: Quick 30-second benchmark to verify SwingBench installation and SOE schema functionality
- **`build-soe-schema.sh`**: Creates a fresh SOE (Sales Order Entry) schema for benchmarking
- **`run-soe-benchmark.sh`**: Runs a configurable benchmark against the SOE schema
- **`cleanup-soe-schema.sh`**: Removes the SOE schema and related objects
- **`build-and-run-soe.sh`**: Automated workflow that builds schema and runs benchmark

## Ansible Deployment

The entire structure is deployed using Ansible playbooks with **consolidated variable management**:

### Main Playbooks
- `main_setup_conditional_benchmark.yml` - **NEW**: Conditional installation based on `benchmark_tool` variable
- `main_setup_complete_benchmark_suite.yml` - Complete installation (Oracle client + TNS + HammerDB + SwingBench)
- `main_setup_oracle_hammerdb_benchmark.yml` - HammerDB setup (Oracle client + TNS + HammerDB)
- `main_setup_oracle_swingbench_benchmark.yml` - SwingBench setup (Oracle client + TNS + SwingBench)

### Variable Management
All configuration variables are **consolidated in `inventory.yaml`** for easier management:
- No separate variable files (`vars/` directory removed)
- Single source of truth for all configuration
- Easy to modify versions, URLs, and paths
- Host-specific variables alongside inventory definition

### Individual Component Playbooks
- `playbooks/oracle-client/install_oracle_client.yml` - Oracle Instant Client installation
- `playbooks/configure-tnsnames/configure_tnsnames.yml` - TNS configuration
- `playbooks/setup-hammerdb/install_setup_hammer_db.yml` - HammerDB installation
- `playbooks/setup-swingbench/install_setup_swingbench.yml` - SwingBench installation

## Maintenance Considerations

### Backup Strategy
- Backup the entire `/opt/ocpv-benchmark/` directory
- Pay special attention to `results/` directory for historical data
- Include `tns/` directory for connection configurations

### Upgrade Path
- Individual tools can be upgraded in their respective directories
- Scripts automatically use the configured version paths
- Results are preserved across upgrades

### Monitoring
- Log files are centrally located in `results/` directories
- Each operation generates timestamped logs
- CSV and XML results provide structured data for analysis 