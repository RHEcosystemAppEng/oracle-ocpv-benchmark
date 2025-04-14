# HammerDB Oracle Benchmark Setup

This repo automates Oracle TPC-C benchmark runs using HammerDB. It includes a set of scripts to handle setup, schema builds, and workload execution. It supports Oracle connections using a `tnsnames.ora` file and TCL scripts.

## Project Structure

```
hammerdb-setup/
├── HammerDB-4.12/               # HammerDB CLI (extracted)
├── install-hammerdb.sh          # Installs HammerDB if not present
├── build.sh                     # Builds TPCC schema
├── run.sh                       # Runs workload benchmark
├── build.tcl                    # TCL script for schema creation
├── run.tcl                      # TCL script to run the test
├── oracle-net/
│   └── tnsnames.ora             # Optional Oracle TNS config
├── results/                     # Benchmark results/logs
```

## Requirements

- **One-Time Installation Oracle Instant Client (version 19+ via `dnf`)**. You can install it using below script :

```shell

./install-oracle-client.sh


```
- Oracle DB should be reachable from your test environment (VM or OCPV). Make sure you can connect with `sqlplus` before running HammerDB.
- The following packages are auto-installed via `build.sh`:
    - `tcl`, `tcl-devel`, `libaio`, `curl`, `unzip`


## Configuration

### 1. TNS Alias (`tnsnames.ora`)

Edit the `tnsnames.ora` in `oracle-net/` to match your environment:

```ora
oralab =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST=yourhost)(PORT=1521))
    (CONNECT_DATA =
      (SERVICE_NAME = pdb1) -- Replace with your actual service name
    )
  )
```

### 2. HammerDB Connection Setup (`build.tcl` / `run.tcl`)

```tcl
set env(TNS_ADMIN) "[file normalize ./oracle-net]"
set env(ORACLE_HOME) "/usr/lib/oracle/19.26/client64"
set env(LD_LIBRARY_PATH) "$env(ORACLE_HOME)/lib"

diset connection instance oralab
diset connection system_user system
diset connection system_password $env(ORACLE_SYSTEM_PASSWORD)
```

### 3. Environment Variables

In both `build.sh` and `run.sh`, export the Oracle password for the `system` user:

```bash
export ORACLE_SYSTEM_PASSWORD=yourpassword
```

## Running the Benchmark

### Build the schema
```bash
./build.sh
```

### Run the workload
```bash
./run.sh
```

### Run with Profiles

The scripts currently support three profiles: small, medium, and large.

Use them to control load size (virtual users, warehouses, duration, etc.) by editing `profile.sh` file

```bash
PROFILE=small ./build.sh
PROFILE=small ./run.sh
```
Or run both in a single step:

```PROFILE=small ./build-and-run.sh```
```PROFILE=scale-run ./build-and-run.sh```

**Note**: Required to cleannup the schema before running each profile


### Output

Logs are saved to:
```
results/hammerdb_run_<timestamp>.log
results/hammerdb_nopm_<timestamp>.log
```

need to create the CSV output then Run:
```bash
./create-csv-result.sh
```

## Resetting the Schema

```sql
DROP USER tpcc CASCADE;
```

## Common Issues

### ORA-12154: Could not resolve connect identifier
- Likely a bad or missing `tnsnames.ora`
- Double-check your `TNS_ADMIN` path

### ORA-65096: Common user or role name must start with C##
- You're probably trying to create a user in the CDB root
- Switch to a pluggable database (like `pdb1`)
- Or manually create the user with `C##` prefix before running the scripts


