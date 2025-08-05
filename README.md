#  Oracle Benchmarking & Observability on OpenShift Virtualization

This repo automates the setup and execution of **HammerDB TPC-C benchmarks** against Oracle databases.We leverage Ansible for provisioning and configuring the environment, enabling automated benchmark execution. 
The solution also provides instructions on how to integrate Oracle's Observability Exporter with Grafana to create an OpenShift-native observability stack. Our primary objective is to automate Oracle performance testing on RHEL VMs provisioned via OpenShift Virtualization


> [!NOTE]
> 📢📢📢 **Red Hat Validation**: These benchmarks have been used by Red Hat to validate the solution on OpenShift Virtualization. For details, refer to http://redhat.com/en/blog/single-instance-oracle-database-openshift-virtualization, and contact Red Hat for further details.

## Project Functionality

This project provides the necessary tooling to automate **Oracle TPC-C benchmark runs** using [HammerDB](https://hammerdb.com/). Included **Ansible playbooks** handle:

* Installation of Oracle client tools.
* Deployment of HammerDB itself.
* Configuration via custom TCL scripts and the TNS Ora file for HammerDB.

Once the environment is deployed, you can initiate **standardized database load tests** directly on the provisioned VM.

Beyond benchmarking, this solution also **provides guidance on:**

* **Prometheus-compatible metric collection** from the Oracle DB using the Oracle Observability Exporter.
* **Visualization of these metrics** through pre-configured Grafana dashboards on OpenShift.

---

## Oracle RAC Performance Test Architecture

![rac-performance_test-arc.png](rac-performance_test-arc.png)

---

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

* A RHEL managed VM (on OpenShift Virtualization).
* Python + Ansible <2.10 installed on your control machine (e.g., your dev workstation).
* Access to an OpenShift cluster (for the monitoring stack).
* OpenShift CLI (`oc`) configured.

**Ansible Version Check:**

Ensure Ansible is `<2.10`:
```bash
pip install "ansible<2.10"
ansible-playbook --version
```

### 1. Ansible Inventory and Parameters Configuration

Before running any playbooks, configure your environment variables and Ansible inventory.


1. **Update `inventory.yaml`**:
   Define your target HammerDB client VM details.

```
      hammerdb_oracle_client_vms ansible_host=<vm-host> ansible_user=<vm_user> ansible_ssh_private_key_file=<> 
```

2. **TNS Configuration**
   Configure Oracle client connectivity via `tnsnames.ora`. These variables define the connection parameters for your Oracle environment. 
   Note: `tnsnames.ora` is set as read-only post-configuration. 
```
       oracle_host=<your_oracle_scan_or_host>  # e.g., oracle RAC host name
       oracle_port=1521                        # Oracle listener port
       oracle_sid=pdb1                         # e.g., pdb1
       oracle_tns_name=ORALAB
       tns_admin_path=/opt/HammerDB/hammerdb-oracle-tns
```
 
3. **Oracle Client Installation**
   Specify Oracle Instant Client RPMs. Default is 19.26, but configurable.

```
    oracle_major_version=19.26
    oracle_minor_version=0.0.0-1.el8
    base_url=https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient/x86_64/getPackage
    oracle_home_path=/usr/lib/oracle/19.26/client64
``` 
   
4. **HammerDB Setup**
   Define HammerDB version and installation paths. Current default is 4.12.
```
      hammerdb_version=4.12
      hammerdb_base_path=/opt/HammerDB
      oracle_client_home=/usr/lib/oracle/19.26/client64
```
5. **Update Environment Variables for HamerDB Script**

You have .env file to set up all the environment variables required for the benchmark.
Please update below environemnt variables:

```bash
#password for oracle system user.
export ORACLE_SYSTEM_PASSWORD=yourpassword
#and if required any other variables  

```


### 2. Test & Run Ansible Playbooks

Navigate to the `ansible` directory on your control node.



```shell

cd ansible
#Test the connection:

ansible -i inventory.yaml -m ping hammerdb_oracle_client_vms


#Run the playbook to install all required dependencies.
ansible-playbook -i inventory.yaml main_setup_oracle_hammerdb_benchmark.yml
```

Individual playbooks can also be executed for granular updates:


```shell
# Install Oracle client
ansible-playbook -i inventory.yaml playbooks/oracle-client/install_oracle_client.yml

# Configure tnsnames.ora
ansible-playbook -i inventory.yaml playbooks/configure-tnsnames/configure_tnsnames.yml

# Install HammerDB and copy scripts
ansible-playbook -i inventory.yaml playbooks/setup-hammerdb/install_setup_hammer_db.yml
```


## Running the Benchmark

Post-Ansible execution, your target VM should have the following directory structure (default base path: /opt/HammerDB): All the dependencies will be inside location as you configured the path with `benchmark_scripts` folder will have all the custom scripts to run the benchmark.
`hammerdb-oracle-tns` will have the tnsnames.ora file.

```shell
[cloud-user@lrangine-vm01 opt]$ tree -d -L 2 /opt/HammerDB
/opt/HammerDB
|-- 4.12
|   |-- agent
|   |-- bin
|   |-- config
|   |-- images
|   |-- include
|   |-- lib
|   |-- modules
|   |-- scripts
|   `-- src
|-- benchmark_scripts
|   `-- results
`-- hammerdb-oracle-tns

13 directories
```

Go to folder `/opt/HammerDB/benchmark_scripts` on the client VM.
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
-- Run the [drop_tpcc_user.sh](ansible/scripts/drop_tpcc_user.sh) script on target client VM. Usually it will be under `/opt/HammerDB/benchmark_scripts`. This script drops the tpcc schema/user.
./drop_tpcc_user.sh
```

## Common Issues

### ORA-12154: Could not resolve connect identifier
- Likely a bad or missing `tnsnames.ora`
- Double-check your `TNS_ADMIN` path

### ORA-65096: Common user or role name must start with C##
- You're probably trying to create a user in the CDB root
- Switch to a pluggable database (like `pdb1`)
- Or manually create the user with `C##` prefix before running the scripts


