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
│   └── 20231104_jdk11/            # SwingBench version directory (November 4, 2023 JDK 11)
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
│       ├── build-soe-schema.sh    # Build SOE schema
│       ├── run-soe-benchmark.sh   # Run SOE benchmark
│       ├── build-and-run-soe.sh   # Combined build and run
│       ├── cleanup-soe-schema.sh  # SOE schema cleanup
│       ├── run-swingbench-test.sh # SwingBench test script
│       └── results/               # SwingBench benchmark results
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
SWINGBENCH_HOME=/opt/ocpv-benchmark/swingbench/20231104_jdk11

# SwingBench Scripts Directory
SWINGBENCH_SCRIPTS=/opt/ocpv-benchmark/scripts/swingbench

# Results Directory (relative to scripts directory)
RESULTS_DIR=./results

# Oracle Connection Details
ORACLE_SERVICE_NAME=your_oracle_service
ORACLE_HOST=your_oracle_host
ORACLE_PORT=1521
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
vi .env                    # Configure environment
./build-and-run-soe.sh     # Run benchmark
ls results/                # View results
```

## Ansible Deployment

The entire structure is deployed using Ansible playbooks:

### Main Playbooks
- `main_setup_complete_benchmark_suite.yml` - Complete installation (Oracle client + TNS + HammerDB + SwingBench)
- `main_setup_oracle_hammerdb_benchmark.yml` - HammerDB setup (Oracle client + TNS + HammerDB)
- `main_setup_oracle_swingbench_benchmark.yml` - SwingBench setup (Oracle client + TNS + SwingBench)

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
- Scripts can be updated independently
- Results from different versions are preserved

### Troubleshooting
- Check tool-specific logs in each tool's `results/` directory
- Verify environment configuration in respective `.env` files  
- Test TNS connectivity using shared `tns/tnsnames.ora`
- Validate installation paths match the documented structure

## Version Information

### Current Tool Versions
- **HammerDB**: 4.12 (stored in `/opt/ocpv-benchmark/hammerdb/4.12/`)
- **SwingBench**: November 4, 2023 JDK 11 release (stored in `/opt/ocpv-benchmark/swingbench/20231104_jdk11/`)
- **Oracle Instant Client**: 19.26 (system-installed in `/usr/lib/oracle/19.26/client64/`)
- **Java**: OpenJDK 11 (required for SwingBench)

This organized structure provides a scalable foundation for Oracle database benchmarking on OpenShift Virtualization platforms. 