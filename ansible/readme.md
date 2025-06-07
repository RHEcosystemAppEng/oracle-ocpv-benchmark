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
```yaml
hammerdb_oracle_client_vms:
  hosts:
    oralab_vm1:
      ansible_host: 127.0.0.1
      ansible_user: rhel
      ansible_ssh_private_key_file: ~/rac-ocpv.pem
      ansible_port: 2222
      ansible_python_interpreter: /usr/libexec/platform-python
```

Check if the ansible able to reach the VM by doing below `ping` test
```shell
ansible -i inventory.yaml -m ping hammerdb_oracle_client_vms
```

If above statement works fine then your ansible setup is successful. And you are good to execute the playbooks and desired vm and should be able to set up with Hammerdb oracle benchmark.

### Setting up the oracle client and hammerdb using Ansible playbooks

If you would like to install everything. This is ideally recommended for the new vm or if you haven't setup hammerdb or oracle client.
You can run below commands from ansible directory
```shell
ansible-playbook -i inventory.yaml main_setup_oracle_hammerdb_benchmark.yml
```

You can also run individual playbooks to set up any of these as desired
```shell
# Run below command to run oracle client
ansible-playbook -i inventory.yaml playbooks/oracle-client/install_oracle_client.yml

# Run below command to configure tnsnames.ora file so that hammerdb can refer it.
ansible-playbook -i inventory.yaml playbooks/configure-tnsnames/configure_tnsnames.yml

# Run below command to set up and configure the hammerdb for oracle benchmark.
ansible-playbook -i inventory.yaml playbooks/setup-hammerdb/install_setup_hammer_db.yml
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
# Once the setup is done validate if the tnsnames.ora is correctly configured and able to access oracle cluster.
export TNS_ADMIN=/etc/Hammerdb-oracle-tns/
sqlplus sys/<PASSWORD>@ORALAB as sysdba

# Creates the user tpcc and grants permissions
CREATE USER tpcc IDENTIFIED BY <tpcc password>;
GRANT CONNECT, RESOURCE, CREATE SESSION TO tpcc;
GRANT DROP, CREATE ANY TABLE TO tpcc;

# drops the user tpcc
DROP USER tpcc CASCADE;
```