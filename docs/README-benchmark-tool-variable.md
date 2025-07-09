# Benchmark Tool Selection with `benchmark_tool` Variable

## Overview
The `benchmark_tool` variable acts as an enum that controls which benchmark tools get installed. This provides flexibility to install HammerDB only, SwingBench only, or both tools.

## Valid Values
- `"hammerdb"` - Install HammerDB only (default)
- `"swingbench"` - Install only SwingBench
- `"all"` - Install both tools

## Configuration

### Default Setting
In `inventory.yaml`, the default is set to install both tools:
```yaml
vars:
  benchmark_tool: "hammerdb"  # Default: installs HammerDB only
```

### Override at Runtime
You can override the variable when running the playbook:

```bash
# Install HammerDB only (default behavior)
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml

# Install only HammerDB
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml -e benchmark_tool=hammerdb

# Install only SwingBench
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml -e benchmark_tool=swingbench

# Explicitly install both tools
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml -e benchmark_tool=all
```

### Change Default in Inventory
You can also change the default in `inventory.yaml`:
```yaml
vars:
  benchmark_tool: "hammerdb"  # Only install HammerDB by default
```

## How It Works

### Play-Level Conditionals
The conditional logic is applied at the play level, making it clean and efficient:

```yaml
# HammerDB play only runs when benchmark_tool is "hammerdb" or "all"
- name: Install and Setup HammerDB for Oracle Benchmark
  import_playbook: playbooks/setup-hammerdb/install_setup_hammer_db.yml
  when: benchmark_tool | default('all') in ['hammerdb', 'all']

# SwingBench play only runs when benchmark_tool is "swingbench" or "all"  
- name: Install and Setup SwingBench for Oracle Benchmark
  import_playbook: playbooks/setup-swingbench/install_setup_swingbench.yml
  when: benchmark_tool | default('all') in ['swingbench', 'all']
```

### Always Installed Components
Regardless of the `benchmark_tool` setting, these components are always installed:
- Oracle Instant Client
- Oracle SQL*Plus
- TNS configuration

## Benefits

✅ **Selective Installation**: Install only the tools you need
✅ **Clean Playbook Structure**: Conditional logic at play level, not task level
✅ **Runtime Flexibility**: Override defaults without changing files
✅ **Backward Compatible**: Default behavior installs everything
✅ **Resource Efficient**: Skip unnecessary downloads and installations

## Use Cases

### Development Environment
```bash
# Install only HammerDB for TPC-C testing
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml -e benchmark_tool=hammerdb
```

### SOE Testing Environment  
```bash
# Install only SwingBench for SOE testing
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml -e benchmark_tool=swingbench
```

### Complete Testing Environment
```bash
# Install both tools for comprehensive testing
ansible-playbook -i inventory.yaml main_setup_conditional_benchmark.yml -e benchmark_tool=all
```

## Validation

The variable uses Ansible's default filter for safety:
```yaml
when: benchmark_tool | default('all') in ['hammerdb', 'all']
```

If `benchmark_tool` is not defined, it defaults to `'all'` ensuring both tools are installed.

## Existing Playbooks
The original individual playbooks remain unchanged and can still be used:
- `main_setup_oracle_hammerdb_benchmark.yml` - HammerDB only
- `main_setup_oracle_swingbench_benchmark.yml` - SwingBench only  
- `main_setup_complete_benchmark_suite.yml` - Both tools
- `main_setup_conditional_benchmark.yml` - **New conditional playbook** 