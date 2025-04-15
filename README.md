# HammerDB Oracle Benchmark Setup

This repo automates Oracle TPC-C benchmark runs using HammerDB. It includes a set of scripts to handle setup, schema builds, and workload execution. It supports Oracle connections using a `tnsnames.ora` file and TCL scripts.

## Project Structure

Github Project Structure:
```
└── ansible
    ├── playbooks                                # Ansible playbooks
    │   ├── configure-tnsnames                   # Ansible playbook to configure tnsnames.ora file 
    │   ├── oracle-client                        # Ansble playbook to install oracle client
    │   └── setup-hammerdb                       # Ansible playbook to install hammerdb and copy the necessary custom scripts under scripts directory to VM.  
    ├── scripts
    │   ├── build.sh                             # Builds TPCC schema
    │   ├── run.sh                               # Runs workload benchmark
    │   ├── build-and-run.sh                     # Builds and Runs workload benchmark
    │   ├── build.tcl                            # TCL script for schema creation
    │   ├── run.tcl                              # TCL script to run the test
    │
    └── templates                                # Ansible templates
```

## Requirements

* Ansible version <2.10. Tested from macbook pro M3.

## Configuration

### 1. Initial Setup using Ansible
Please check the readme to set up in [ansible](ansible) for detailed instructions. You need ansible<2.10 version to be compatible with RHEL 8 VM.

Update the target vm details in ansible inventory.ini. Below playbook installs oracle client, hammer DB and copies all the scripts to target VM.

```shell
#Run the playbook to install all required dependencies.
cd ansible
ansible-playbook -i inventory.ini main_setup_oracle_hammerdb_benchmark.yml
```

Now your target VM should have set up the project structure as below. All the dependencies will be inside `/opt/HammerDB` path. `benchmark_scripts` folder will have all the custom scripts to run the benchmark.
`hammerdb-oracle-tns` will have the tnsnames.ora file.

```shell
[cloud-user@lrangine-vm01 HammerDB]$ tree -d -L 2 /opt/HammerDB
/opt/HammerDB
|-- 4.12
|   |-- agent
|   |-- benchmark_scripts
|   |-- bin
|   |-- config
|   |-- images
|   |-- include
|   |-- lib
|   |-- modules
|   |-- scripts
|   `-- src
`-- hammerdb-oracle-tns
```

### 2. Environment Variables

You have .env file to set up all the environment variables required for the benchmark.
Please update below environemnt variables:

```bash
#password for oracle system user.
export ORACLE_SYSTEM_PASSWORD=yourpassword
export TNS_ADMIN=/opt/HammerDB/hammerdb-oracle-tns/
export ORACLE_INSTANCE=${ORACLE_INSTANCE:-ORALAB}
```

## Running the Benchmark
Go to folder `/opt/HammerDB/4.12/benchmark_scripts` on the client VM.
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


