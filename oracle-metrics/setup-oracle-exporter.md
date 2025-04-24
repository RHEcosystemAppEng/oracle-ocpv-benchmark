# 📊 Oracle Observability Exporter Setup on OpenShift

This guide covers:

- Create the oracle user with required permissions.
- Deploy the oracle exporter pod.
- Set up the prometheus `ServiceMonitor` to scrape the data.

---
## 🧱 Prerequisites

- OpenShift CLI (`oc`) installed and configured
- User with appropriate permissions
- Create all necessary namespaces mentioned in the `deployment` yaml files.

---
### Step 1: Create the oracle user with the required permissions
You can create the oracle user with the required permissions mentioned on the [oracle-db-appdev-monitoring project](https://github.com/oracle/oracle-db-appdev-monitoring?tab=readme-ov-file#database-permissions-required).

Following are some sample queries and not recommend to use AS-IS:

```shell
CREATE USER metrics_user IDENTIFIED BY <SELECT_PASSWORD>;
GRANT CONNECT TO metrics_user;
GRANT SELECT ANY DICTIONARY TO metrics_user;
GRANT SELECT ON V_$SESSION TO metrics_user;
GRANT SELECT ON V_$SYSSTAT TO metrics_user;

GRANT SELECT ON V_$SYSSTAT TO metrics_user;
GRANT SELECT ON V_$SESSION TO metrics_user;
GRANT SELECT ON V_$PROCESS TO metrics_user;
GRANT SELECT ANY DICTIONARY TO metrics_user;

# This will grant all the DBA permissions.
GRANT DBA TO metrics_user;
```
### Step 2: Create the oracle credentials secret
Create the Oracle Credentials secret so that oracle exporter can refer that.

```shell
oc create secret generic oracle-observability-secrets \
--from-literal=DB_USERNAME="metrics_user" \
--from-literal=DB_PASSWORD=<REPLACE_PASSWORD> \
--from-literal=DB_CONNECT_STRING=<ORACLE_HOST>:1521/pdb1
```

### Step 3: Deploy the oracle observability pod.

Deploy the oracle observability pod using below command:

```shell
oc apply -f oracle-observability-exporter-deployment.yaml
```

### Step 4: Check if the pod is up.
After deployment, it will take some time to spin up the pod. Observe the pod logs/events for any errors.

The route will not be added by default so add the route to the pod and see if the API `/metrics` is up.

```
http://<ROUTE_of_Pod>/metrics
```
Above API will return prometheus metrics exposed as part of the oracle observability pod.  

### Step 5: set up the prometheus ServiceMonitor.
Now oracle observability pod is up but openshift prometheus does not scrape the data automatically until you create a `ServiceMonitor`

```shell
oc apply -f oracle-servicemonitor.yaml
```

Once this is implemented you should be able to see the   data in openshift prometheus instance.