# Setting up the hammerdb oracle benchmark using ansible

## Introduction
In this tutorial we are setting up the hammerdb oracle benchmark on the openshift virtual machine.  

## Prerequisites
* Managed node with Python 3.6.X. Rhel 8 comes with default python 3.6.X version. Managed node is on OPC virtual environment.
* Ansible controller node with Ansible version <2.10. Tested from macbook pro M3.


### Check the managed ansible VM is having Python installed.

Once you have the VM from openshift virtualization platform [register](https://console.redhat.com/insights/connector/activation-keys) with redhat to configure the repo.
```shell
# Adding the rhel repos to install any packages as part of the ansible playbook.
sudo subscription-manager register --activationkey=<> --org=<>
```

Once you enable the repo find the python interpreter path which is available by default on RHEL8.
```shell
# Below commands will help to find the python path.
# Check if the python is available at default path on rhel8
$ /usr/libexec/platform-python --version
Python 3.6.8

# If it is not available in above path then you can find installed path with below commands
which python3
which python

#If you want to make this as default python version then you can add symlink of python
#WARNING: This will change the current python version so if you any other dependencies with different python versions those may not work.
sudo ln -sf /usr/libexec/platform-python /usr/bin/python
sudo ln -sf /usr/libexec/platform-python /usr/bin/python3

# Check python version
$which python
/usr/bin/python
$ which python3
/usr/bin/python3
$ python --version
Python 3.6.8
```
Make sure to update the ansible inventory file to use the above python interpreter. You can check the further sections how to do it.

### Check the Controlled node having ansible
Make sure the controller node is having ansible installed. Since the managed node RHEL8 is having python 3.6x version we need to have ansible playbook which is compatible with python 3.6x.

In our case we have tested by installing ansible version of 2.9.X. Tested this ansible playbook from the macbook pro.

```shell
#Install ansible using pip
pip install "ansible<2.10"
% ansible-playbook --version
ansible-playbook 2.9.27
  config file = None
  configured module search path = ['/Users/lokeshrangineni/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /opt/homebrew/anaconda3/envs/feast/lib/python3.11/site-packages/ansible
  executable location = /opt/homebrew/anaconda3/envs/feast/bin/ansible-playbook
  python version = 3.11.10 (main, Oct  3 2024, 02:26:51) [Clang 14.0.6 ]
```


### Ansible inventory set up.

If you can't expose the VM externally but need to run Ansible, you can port-forward SSH from the VM to your local machine:

```shell
virtctl port-forward <vm-name> 2222:22 -n <namespace>
```

you can also SSH from your local machine as below:
```shell
ssh rhel@localhost -p 2222
```

Now add below VM to ansible inventory.yaml. `ansible_ssh_private_key_file` is the private key to do the ssh in to VM. This path and necessary fields needs to be corrected as per your scenario.

All configuration variables are now consolidated in the inventory file for easier management:

```yaml
all:
  children:
    oracle_benchmark_client_vms:
      hosts:
        oralab_vm1:
          ansible_host: 127.0.0.1
          ansible_user: rhel
          ansible_ssh_private_key_file: ~/rac-ocpv.pem
          ansible_port: 2222
          ansible_python_interpreter: /usr/libexec/platform-python
      vars:
        # Benchmark Tool Selection (enum-like variable)
        # Valid values: "hammerdb", "swingbench", "all"
        benchmark_tool: "all"  # Default: installs both tools
        
        # SwingBench Configuration
        swingbench_version: 25052023_jdk11
        swingbench_url: "https://github.com/domgiles/swingbench-public/releases/download/historic/swingbench{{ swingbench_version }}.zip"
        required_java_version: "11"
        
        # HammerDB Configuration
        hammerdb_version: 4.12
        
        # TNS Configuration
        default_tns_entry: "ORALAB_STANDALONE"
        oracle_tns_entries:
          - tns_name: "ORALAB"
            host: <oralab-oracle-rac host name>
            port: "1521"
            sid: "pdb1"
          - tns_name: "ORALAB_STANDALONE"
            host: <oralab-oracle-standalone host name>
            port: "1521"
            sid: "pdb1"
        
        # System Configuration
        benchmark_base_path: /opt/ocpv-benchmark
        scripts_base_path: /opt/ocpv-benchmark/scripts
        tns_admin_path: /opt/ocpv-benchmark/tns
        system_user: cloud-user
        system_group: cloud-user
        
        # Oracle Client Configuration  
        oracle_major_version: 19.26
        oracle_minor_version: 0.0.0-1.el8
        oracle_home_path: /usr/lib/oracle/19.26/client64
```

Check if the ansible able to reach the VM by doing below `ping` test
```shell
ansible -i inventory.yaml -m ping oracle_benchmark_client_vms
```

If above statement works fine then your ansible setup is successful. And you are good to execute the playbooks and desired vm and should be able to set up with Hammerdb oracle benchmark.

### Setting up the Oracle client and benchmark tools using Ansible playbooks

#### NEW: Conditional Benchmark Tool Installation

Use the **conditional playbook** to selectively install HammerDB, SwingBench, or both tools:

```shell
# Install both tools (default behavior - reads benchmark_tool from inventory.yaml)
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml

# Install only HammerDB
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml -e benchmark_tool=hammerdb

# Install only SwingBench  
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml -e benchmark_tool=swingbench

# Explicitly install both tools
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml -e benchmark_tool=all
```

#### Legacy Playbooks (Still Available)

If you prefer the original approach, you can still use the individual tool playbooks:

```shell
# Complete HammerDB setup (Oracle client + TNS + HammerDB)
ansible-playbook -i inventory.yaml main_setup_oracle_hammerdb_benchmark.yml

# Complete SwingBench setup (Oracle client + TNS + SwingBench)
ansible-playbook -i inventory.yaml main_setup_oracle_swingbench_benchmark.yml

# Complete installation (Oracle client + TNS + both tools)
ansible-playbook -i inventory.yaml main_setup_complete_benchmark_suite.yml
```

#### Individual Component Playbooks

You can also run individual playbooks to set up specific components:
```shell
# Install Oracle Instant Client only
ansible-playbook -i inventory.yaml playbooks/oracle-client/install_oracle_client.yml

# Configure TNS names only
ansible-playbook -i inventory.yaml playbooks/configure-tnsnames/configure_tnsnames.yml

# Install HammerDB only (requires Oracle client)
ansible-playbook -i inventory.yaml playbooks/setup-hammerdb/install_setup_hammer_db.yml

# Install SwingBench only (requires Oracle client) 
ansible-playbook -i inventory.yaml playbooks/setup-swingbench/install_setup_swingbench.yml
```

#### Variable Configuration

All variables are now consolidated in `inventory.yaml`. To customize:

1. **Change benchmark tool selection**: Modify `benchmark_tool` in inventory.yaml
2. **Update Oracle connectivity**: Modify `oracle_tns_entries` section
3. **Change tool versions**: Update `hammerdb_version` or `swingbench_version`
4. **Modify paths**: Update `benchmark_base_path` and related paths

## Running SwingBench Benchmarks

After installation, SwingBench provides several ready-to-use scripts:

### Available Scripts

```shell
# Navigate to SwingBench scripts directory
cd /opt/ocpv-benchmark/scripts/swingbench

# Quick verification test (30-second benchmark)
./simple-swingbench-test.sh

# Create/rebuild SOE schema
./build-soe-schema.sh

# Run full benchmark
./run-soe-benchmark.sh

# Clean up SOE schema
./cleanup-soe-schema.sh

# Complete workflow (build schema + run benchmark)
./build-and-run-soe.sh
```

### Script Descriptions

- **`simple-swingbench-test.sh`**: Quick 30-second benchmark to verify SwingBench installation and SOE schema functionality
- **`build-soe-schema.sh`**: Creates a fresh SOE (Sales Order Entry) schema for benchmarking
- **`run-soe-benchmark.sh`**: Runs a configurable benchmark against the SOE schema
- **`cleanup-soe-schema.sh`**: Removes the SOE schema and related objects
- **`build-and-run-soe.sh`**: Automated workflow that builds schema and runs benchmark

### Configuration

All scripts use environment variables from `.env` file in the SwingBench scripts directory:

```bash
# Example configuration (automatically created by Ansible)
export SWINGBENCH_HOME=/opt/ocpv-benchmark/swingbench/25052023_jdk11
export RESULTS_DIR=/opt/ocpv-benchmark/scripts/swingbench/results
export ORACLE_SID=ORALAB_STANDALONE
export SOE_USER=soe
export SOE_PASSWORD=Chang4On
export SCALE_FACTOR=1
export USER_COUNT=4
export RUN_TIME=1
```

### Results Location

All benchmark results are saved to the results directory on the client VM:

```bash
# Results directory structure
/opt/ocpv-benchmark/scripts/swingbench/results/
├── swingbench_simple_test.log               # Simple test output
├── soe_schema_build_YYYYMMDD_HHMMSS.log    # Schema build logs
├── soe_benchmark_run_YYYYMMDD_HHMMSS.log   # Benchmark run logs
├── soe_results_YYYYMMDD_HHMMSS.xml         # XML results
└── soe_results_YYYYMMDD_HHMMSS.csv         # CSV results
```

### Viewing Results

```shell
# View recent results
cd /opt/ocpv-benchmark/scripts/swingbench/results
ls -la

# View CSV results (contains performance metrics)
cat soe_results_*.csv

# View detailed logs
tail -f soe_benchmark_run_*.log
```

## Running HammerDB Benchmarks

For HammerDB usage, navigate to the HammerDB scripts directory:

```shell
cd /opt/ocpv-benchmark/scripts/hammerdb
# Follow existing HammerDB documentation
```

## Debugging hammerdb issues
Refresh hammerdb cache if the test does not reflect your configuration changes.
```shell
#refresh hammerdb cache/configs
rm /tmp/database.db
```

## Troubleshooting

### SwingBench Issues

1. **Config file errors**: SwingBench automatically restores config files from backups
2. **Connection issues**: Verify TNS configuration and Oracle connectivity
3. **Permission issues**: Ensure proper file permissions on scripts directory
4. **Java version**: SwingBench requires Java 11

### Common Solutions

```shell
# Test database connectivity
sqlplus sys/password@TNS_NAME as sysdba

# Check Java version
java -version

# Verify SwingBench installation
ls -la /opt/ocpv-benchmark/swingbench/25052023_jdk11/bin/

# Check script permissions
chmod +x /opt/ocpv-benchmark/scripts/swingbench/*.sh
```