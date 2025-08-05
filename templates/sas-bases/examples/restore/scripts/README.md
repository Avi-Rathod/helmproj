---
category: backupRestore
tocprty: 16
---

# Restore Scripts

## Overview

This README file contains information about the execution of scripts that are potentially required for restoring the SAS Viya Platform from a backup.

## Append the Execute Permissions to Scripts

To execute the scripts described in this README, append the execute permission by running the following command.

```bash
chmod +x ./sas-backup-pv-copy-cleanup.sh ./scale-up-cas.sh ./sas-backup-pv-copy-cleanup-using-pvcs.sh
```

## Clean Up CAS Persistent Volume Claims

Persistent volumes claims (PVCs) are used by the CAS server to restore CAS data. To clean up the CAS PVCs after the restore job has completed,
execute the sas-backup-pv-copy-cleanup.sh or the sas-backup-pv-copy-cleanup-using-pvcs.sh bash script.
Both scripts have three arguments: namespace, operation to perform, and a comma-separated list of CAS instances or persistent volume claims.
If you are attempting a restore after a successful SAS Viya 3.x to SAS Viya 4 migration, method 2 is recommended.

### Method 1 - Use a List of CAS instances

```bash
./sas-backup-pv-copy-cleanup.sh [namespace] [operation] "[CAS instances list]"
```

Here is an example:

```bash
./sas-backup-pv-copy-cleanup.sh viya04 remove "default"
```

**Note:** The default CAS instance name is "default" if the user has not changed it.

Use the following command to determine the name of the CAS instances.

```bash
kubectl -n name-of-namespace get casdeployment -L 'casoperator.sas.com/instance'
```

Verify that the output for the command contains the name of the CAS instances. Here is an example of the output:

```bash
test.host.com> kubectl -n viya04 get casdeployment -L 'casoperator.sas.com/instance'
NAME      AGE   INSTANCE
default   14h   default
```

In this example, the CAS instance is named "default". If the instance value in the output is empty, use "default" as the instance value.

### Method 2 - Use a list of Persistent Volume Claims

To get the list of persistent volume claims for CAS instances, execute the following command.

```bash
kubectl -n name-of-namespace get pvc -l 'sas.com/backup-role=provider,app.kubernetes.io/part-of=cas'
```

Verify that the output contains the persistent volume claims.

```bash
test.host.com> kubectl -n viya04 get pvc -l 'sas.com/backup-role=provider,app.kubernetes.io/part-of=cas'
NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
cas-acme-default-data             Bound    pvc-6c4b3b65-cc11-4757-ac00-059d8e19f307   8Gi        RWX            nfs-client     20h
cas-acme-default-permstore        Bound    pvc-1a7cc621-5770-4e5d-b829-46eaad433460   100Mi      RWX            nfs-client     20h
cas-cyberdyne-default-data        Bound    pvc-cd5c173a-9bcf-4649-bea3-ea463930c9b4   8Gi        RWX            nfs-client     20h
cas-cyberdyne-default-permstore   Bound    pvc-253ff153-f309-4700-bef1-e041f63a7810   100Mi      RWX            nfs-client     20h
cas-default-data                  Bound    pvc-52d98061-d296-40f0-92e9-eaa34ca856c5   8Gi        RWX            nfs-client     21h
cas-default-permstore             Bound    pvc-cd8c3e86-a848-4029-9456-5841c85b15fd   100Mi      RWX            nfs-client     21h
```

Select list of data and permstore persistent volume claim for a CAS instance.

```bash
./sas-backup-pv-copy-cleanup-using-pvcs.sh [namespace] [operation] "[PVCs]"
```

Here is an example:

```bash
./sas-backup-pv-copy-cleanup-using-pvcs.sh viya04 remove "cas-default-data,cas-default-permstore"
```

## Copy Backup Data to and from Backup Persistent Volume Claims

You can also use a Kubernetes job (sas-backup-pv-copy-cleanup-job) to copy backup data to and from the backup persistent volume claims like sas-common-backup-data and sas-cas-backup-data.

### Method 1 -  Use a List of CAS instances

1. To create a copy job from the cronjob sas-backup-pv-copy-cleanup-job, execute the sas-backup-pv-copy-cleanup.sh script with three arguments: namespace,
 operation to perform, and a comma-separated list of CAS instances.

   ```bash
   ./sas-backup-pv-copy-cleanup.sh [namespace] [operation] "[CAS instances list]"
   ```

   Here is an example:

   ```bash
   ./sas-backup-pv-copy-cleanup.sh viya04 copy "default"
   ```

   **Note:** The default CAS instance name is "default" if the user hasn't changed it.

2. The script creates a copy job for each CAS Instance that is included in the comma-separated list of CAS instances. Check for the sas-backup-pv-copy-job pod that is created for each individual CAS Instance

   ```bash
   kubectl -n name-of-namespace get pod | grep -i sas-backup-pv-copy
   ```

   If you do not see the results you expect, see the console output of the sas-backup-pv-copy-cleanup.sh script.

### Method 2 -  Use a list of Persistent Volume Claims

1. To create a copy job from the cronjob sas-backup-pv-copy-cleanup-job, execute the sas-backup-pv-copy-cleanup-using-pvcs.sh
script with three arguments: namespace, operation to perform, and the backup persistent volume claim particular to the CAS instance.

   To get the list of backup persistent volume claims for CAS instances, execute the following command.

   ```bash
   kubectl -n name-of-namespace get pvc -l 'sas.com/backup-role=storage,app.kubernetes.io/part-of=cas'
   ```

   Verify that the output contains the name of backup persistent volume claim particular to the cas instances.

   ```bash
   test.host.com> kubectl -n viya04 get pvc -l 'sas.com/backup-role=storage,app.kubernetes.io/part-of=cas'
   NAME                                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
   sas-cas-backup-data                     Bound    pvc-3b16a5c0-b4af-43a1-95f7-53aa30103a59   8Gi        RWX            nfs-client     21h
   sas-cas-backup-data-acme-default        Bound    pvc-ceb3f86d-c0da-419b-bc06-825a6cddb5d9   4Gi        RWX            nfs-client     21h
   sas-cas-backup-data-cyberdyne-default   Bound    pvc-306f6b28-7d5a-4769-885c-b21d3b734207   4Gi        RWX            nfs-client     21h
   ```

   Select backup persistent volume claim for a CAS instance.

   ```bash
   ./sas-backup-pv-copy-cleanup-using-pvcs.sh [namespace] [operation] "[PVC]"
   ```

   Here is an example:

   ```bash
   ./sas-backup-pv-copy-cleanup-using-pvcs.sh viya04 copy "sas-cas-backup-data"
   ```

2. The script creates a copy job that mounts the cas specific backup persistent volume claim and the sas-common-backup-data persistent volume claim. Check for the sas-backup-pv-copy-job pod that is created.

   ```bash
   kubectl -n name-of-namespace get pod | grep -i sas-backup-pv-copy
   ```

If you do not see the results you expect, see the console output of the sas-backup-pv-copy-cleanup.sh script.

The copy job pod mounts two persistent volume claims per CAS instance. The 'sas-common-backup-data' PVC is mounted at '/sasviyabackup' and the 'sas-cas-backup-data' PVC is mounted at '/cas'.

## Scaling CAS Deployments

To scale up the CAS deployments that are used to restore CAS data for each CAS instance, execute the scale-up-cas.sh bash script with two arguments: namespace and a comma-separated list of CAS instances.

```bash
./scale-up-cas.sh [namespace] "[CAS instances list]"
```

Here is an example:

```bash
./scale-up-cas.sh viya04 "default"
```

**Note:** The default CAS instance name is "default" if the user has not changed it.

Ensure that all the required sas-cas-controller pods are scaled up, especially if you have multiple CAS controllers.

## Granting Security Context Constraints for Copy and Cleanup Job on an OpenShift Cluster

The `$deploy/sas-bases/examples/restore/scripts/openshift` directory contains a file to grant security context constraints (SCCs) for the sas-backup-pv-copy-cleanup-job pod on an OpenShift cluster.
If you enable host launch on an OpenShift cluster, use the `sas-backup-pv-copy-cleanup-job-scc.yaml` SCC.
If you did not enable host launch on an OpenShift cluster and are facing issues related to file deletion, use the `sas-backup-pv-copy-cleanup-job-scc-fsgroup.yaml` SCC.

**Note:** The security context constraint needs to be applied only if CAS is configured to allow for host identity.

1. Use one of the following commands to apply the SCCs.

   Using kubectl

   ```sh
   kubectl apply -f sas-backup-pv-copy-cleanup-job-scc.yaml
   ```

   or

   ```sh
   kubectl apply -f sas-backup-pv-copy-cleanup-job-scc-fsgroup.yaml
   ```

   Using the OpenShift CLI

   ```sh
   oc create -f sas-backup-pv-copy-cleanup-job-scc.yaml
   ```

   or

   ```sh
   oc create -f sas-backup-pv-copy-cleanup-job-scc-fsgroup.yaml
   ```

2. Use the following command to link the SCCs to the appropriate Kubernetes service account.
Replace the entire variable {{ .values.NAME_OF_NAMESPACE }}, including the braces, with the Kubernetes namespace used for the SAS Viya platform.

   ```sh
   oc -n {{.Values.NAME_OF_NAMESPACE }} adm policy add-scc-to-user sas-backup-pv-copy-cleanup-job -z sas-viya-backuprunner
   ```
