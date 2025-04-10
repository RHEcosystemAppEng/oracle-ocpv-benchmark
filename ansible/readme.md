# Setting up the hammerdb oracle benchmark using ansible

## Introduction
In this tutorial we are setting up the hammerdb oracle benchmark on the openshift virtual machine. We have tested it on the RHEL 8. 
* We are using ansible to automate all the steps.
* I have tested the steps documented by running ansible from my personal laptop. i.e., macbook pro m3.

### Set up the openshift VM to run Ansible playbooks
Once you have the VM from openshift virtualization platform [register](https://console.redhat.com/insights/connector/activation-keys) with redhat to configure the repo.
```shell
#adding the rhel repos to install any packages.
sudo subscription-manager register --activationkey=<> --org=<>
```

You need to install the python3 so that ansible automation can work. If you are using rhel8 then may be you need to upgrade python version. We need above 3.7 version.
```shell
# By default python will be lower version of python so enable 3.9 module
sudo dnf module enable -y python39

# Install python 3.9
sudo dnf install -y python39

# find installed path
which python3.9

#If you want to make this as default python version then you can add symlink of python
#WARNING: This will change the current python version so if you any other dependencies with different python versions those may not work.
sudo ln -sf /usr/bin/python3.9 /usr/bin/python
sudo ln -sf /usr/bin/python3.9 /usr/bin/python3

# Check python version
which python
[user01@user-vm01 ~]$ python --version
Python 3.9.20
```

If you can't expose the VM externally but need to run Ansible, you can port-forward SSH from the VM to your local machine:

```shell
virtctl port-forward <vm-name> 2222:22 -n <namespace>
```

you can also SSH from your local machine as below:
```shell
ssh rhel@localhost -p 2222
```

Now add below VM to ansible inventory.ini. `ansible_ssh_private_key_file` is the private key to do the ssh in to VM. This path needs to be corrected as per your scenario.
```shell
hammerdb-oracle-client-vms ansible_host=127.0.0.1 ansible_user=rhel ansible_ssh_private_key_file=~/.ssh/id_ed25519 ansible_port=2222 ansible_python_interpreter=/usr/bin/python3
```

Check if the ansible able to reach the VM by doing below simple test
```shell
ansible -i inventory.ini -m ping hammerdb-oracle-client-vms
```

If above statement works fine then your ansible setup is successful. And you are good to execute the playbooks and desired vm and should be able to set up Hammerdb oracle benchmark.

### Setting up the oracle client and hammerdb using Ansible playbooks

If you would like to install everything. This is ideally recommended for the new vm or if you haven't setup hammerdb or oracle client.
You can run below commands from ansible directory
```shell
ansible-playbook -i inventory.ini main_setup_oracle_hammerdb_benchmark.yml
```

You can also run individual playbooks to set up any of these as desired
```shell
# Run below command to run oracle client
ansible-playbook -i inventory.ini playbooks/oracle-client/install_oracle_client.yml

# Run below command to configure tnsnames.ora file so that hammerdb can refer it.
ansible-playbook -i inventory.ini playbooks/configure-tnsnames/configure_tnsnames.yml

# Run below command to set up and configure the hammerdb for oracle benchmark.
ansible-playbook -i inventory.ini playbooks/oracle-client/install_setup_hammer_db.yml
```


## Debugging hammerdb issues
Refresh hammerdb cache if the test does not reflect your configuration changes.
```shell
#refresh hammerdb cache/configs
rm /tmp/database.db
```

Often hammerdb loads the default configurations so it is useful to see the effective configuration using below commands.
```shell
#run in interactive mode
./hammerdbcli

#enter below command to see all the effective configurations.
print dict
```

## Some helpful Oracle commands

```shell
# Creates the user tpcc and grants permissions
CREATE USER tpcc IDENTIFIED BY <tpcc password>;
GRANT CONNECT, RESOURCE, CREATE SESSION TO tpcc;
GRANT DROP, CREATE ANY TABLE TO tpcc;

# drops the user tpcc
DROP USER tpcc CASCADE;
```