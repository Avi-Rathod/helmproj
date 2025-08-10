---
category: Inventory Collector
tocprty: 1
---

# Using the Inventory Collector

## Overview

The Inventory Collector is a CronJob that contains two Jobs.
They are available to run after deployment is fully up and running.
The first Job creates inventory tables and the second Job creates an inventory
comparison table. Tables are created in the protected SystemData caslib
and used by SAS Inventory Reports located in the
`Content/Products/SAS Environment Manager/Dashboard Items` folder.
Access to the tables and reports are restricted to users that are
members of the SAS Administrators group.

For more information, see [SAS Help Center Documentation](https://go.documentation.sas.com/doc/en/sasadmincdc/v_032/calmigration3x/p0s8n6d5si7oqun1ixkvuw10mzcx.htm#n19zyr5az9t61xn1wvid4nidbs09)

## Usage

## Inventory Collector Job

The Inventory Collector Job must be run before the Inventory Comparison Job. It
collects an inventory of artifacts created by various SAS Viya platform services. It also
creates the SASINVENTORY4 and SASVIYAINVENTORY4_CASSVRDETAILS CAS tables in the
SystemData caslib that are referenced by the SAS Viya 4 Inventory Report.

### Run Inventory Collection on All Tenants

```bash
kubectl create job --from=cronjob/sas-inventory-collector sas-inventory-collector-job
```

### Run Inventory Collection on a Single Tenant
Set the TENANT environment variable to “provider”, then create and run the Job. Here
is an example:

```bash
kubectl set env cronjob/sas-inventory-collector TENANT=acme
kubectl create job --from=cronjob/sas-inventory-collector sas-inventory-collector-job
```
### Run Inventory Collection on the Provider Tenant
Set the TENANT environment variable to "provider", then create and run the Job. Here
is an example:

```bash
kubectl set env cronjob/sas-inventory-collector TENANT=provider
kubectl create job --from=cronjob/sas-inventory-collector sas-inventory-collector-job
```

### Remove the TENANT Environment Variable

```bash
kubectl set env cronjob/sas-inventory-collector TENANT-
```

### Schedule an Inventory

The sas-inventory-collector CronJob is disabled by default.
To enable it, run this command:

```bash
kubectl patch cronjob sas-inventory-collector -p '{"spec":{"suspend": false}}'
```

### Schedule an Inventory in Single-Tenant Environments

A schedule can be set in the CronJob Kubernetes resource by using the kubectl patch
command. For example, to run once a day at midnight, run this command:

```bash
kubectl patch cronjob sas-inventory-collector -p '{"spec":{"schedule": "0 0 * * *"}}'
```

Scheduling the CronJob in the cluster is permitted for single-tenant environments.

### Schedule an Inventory in Multi-Tenancy Environments

Multi-tenant environments should run CronJobs outside the cluster on a machine where
the admin can run kubectl commands. This approach allows multi-tenant Jobs to run
independently and simultaneously. Here is an example that runs the **provider**
tenant at midnight and the **acme** tenant five minutes later:

Add a crontab to a server with access to kubectl and the cluster namespace
```bash
$ crontab -e
```
Crontab entries
```bash
0 0 * * * /PATH_TO/inventory-collector.sh provider
5 0 * * * /PATH_TO/inventory-collector.sh acme
```

## Sample inventory-collector.sh

This sample script can be called by a crontab entry in a server running outside the cluster.
```bash
#!/bin/bash
TENANT=$1
export KUBECONFIG=/PATH_TO/kubeconfig
# unset the COMPARISON environment variable if set
kubectl set env cronjob/sas-inventory-collector COMPARISON-
# set the TENANT= environment variable
/PATH_TO/kubectl set env cronjob/sas-inventory-collector TENANT=$TENANT
# delete any previously run job
/PATH_TO/kubectl delete job sas-inventory-collector-$TENANT
# run the job
/PATH_TO/kubectl create job --from=cronjob/sas-inventory-collector sas-inventory-collector-$TENANT
```

---

## Inventory Comparison Job

The inventory comparison job compares two inventory tables. The resulting table is used by the SAS Viya Inventory Comparison report.

### Run Inventory Comparison in an non-MT environment
- set the COMPARISON environment variable to "true"

```bash
kubectl set env cronjob/sas-inventory-collector COMPARISON=true
kubectl delete job sas-inventory-comparison-job
kubectl create job --from=cronjob/sas-inventory-collector sas-inventory-comparison-job
kubectl set env cronjob/sas-inventory-collector COMPARISON-
```

### Run Inventory Comparison on the Provider Tenant in an MT environment
- set the COMPARISON environment variable to "true"
- set the TENANT environment variable to "provider"

Here is an example:

```bash
kubectl set env cronjob/sas-inventory-collector TENANT=provider
kubectl set env cronjob/sas-inventory-collector COMPARISON=true
kubectl create job --from=cronjob/sas-inventory-collector sas-inventory-comparison-job
kubectl set env cronjob/sas-inventory-collector COMPARISON-
```
### Run Inventory Comparison for a single tenant in a MT environment
- set the COMPARISON environment variable to "true"
- set the TENANT environment variable to the "tenant-name"

```bash
kubectl set env cronjob/sas-inventory-collector TENANT=<tenant-name>
kubectl set env cronjob/sas-inventory-collector COMPARISON=true
kubectl delete job sas-inventory-comparison-job
kubectl create job --from=cronjob/sas-inventory-collector sas-inventory-comparison-job
kubectl set env cronjob/sas-inventory-collector COMPARISON-
```

### Comparing Viya 3 to Viya 4+ after a migration
Inventory collection or scanning as it is referred to in SAS Viya 3, is typically run before a migration.
Running a collection then a comparison, the first time following a migration, will compare pre-migration to post-migration artifacts.
Subsequent collection/comparison runs will compare post-migration to post-migration artifacts.
To re-run a pre-migration to post migration comparison, set the COMPARISON="migration" environment variable.

```bash
kubectl set env cronjob/sas-inventory-collector TENANT=<tenant-name>
kubectl set env cronjob/sas-inventory-collector COMPARISON=migration
kubectl delete job sas-inventory-comparison-job
kubectl create job --from=cronjob/sas-inventory-collector sas-inventory-comparison-job
kubectl set env cronjob/sas-inventory-collector COMPARISON-
```