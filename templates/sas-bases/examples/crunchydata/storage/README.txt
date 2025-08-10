---
category: dataServer
tocprty: 20
---

# Configuration Settings for PostgreSQL Storage

## Overview

PostgreSQL data is stored inside Kubernetes PersistentVolumeClaims (PVCs). This README describes how to adjust PostgreSQL PVC settings such as size and storage classes.

**Important:** Changing the storage class or access modes used for PostgreSQL-related PVCs after the initial SAS Viya platform deployment is not supported.

## Installation

1. Copy the file `$deploy/sas-bases/examples/crunchydata/storage/crunchy-storage-transformer.yaml` into your `$deploy/site-config/crunchydata/` directory.

2. Rename the copied file to something unique. SAS recommends following the naming convention `{{ .Values.CLUSTER_NAME }}-crunchy-storage-transformer.yaml`. For example, a copy of the transformer targeting Platform PostgreSQL could be named `platform-postgres-crunchy-storage-transformer.yaml`.

3. Adjust the values in your copied file following the in-line comments.

4. Add a reference to the file in the transformers block of the base kustomization.yaml (`$deploy/kustomization.yaml`), including adding the block if it doesn't already exist. The following example shows the content based on a file named `platform-postgres-crunchy-storage-transformer.yaml`:

   ```yaml
   transformers:
   - site-config/crunchydata/platform-postgres-crunchy-storage-transformer.yaml
   ```

For reference, SAS uses the following default values:

* PostgreSQL PVCs

  * Storage size - 128Gi
  * Access mode - ReadWriteOnce
  * Storage class - Default storage class in your Kubernetes cluster

* pgBackrest PVCs

  * Storage size - 128Gi
  * Access mode - ReadWriteOnce
  * Storage class - Default storage class in your Kubernetes cluster

## Additional Resources

For more information, see
[SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
