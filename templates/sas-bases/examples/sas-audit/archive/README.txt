---
category: auditing
tocprty: 5
---

# SAS Audit Archive Configuration

## Overview

The SAS Audit service can be configured to periodically archive audit records to file. If this feature is enabled, then a PersistentVolumeClaim must be created as the output location for these archive files.

**Note:** Because this task requires the SAS Environment Manager, it can only be performed after a successful deployment.

## Prerequisites

Archiving is disabled by default, so you must enable the feature to use it.
As an administrator, open the Audit service configuration in SAS Environment Manager and change the following settings to the specified values.

| Setting Name                           | Value                                                       |
| ---------------------------------------------------| ----------------------------------------------------------- |
| sas.audit.archive.process.storageType              | local                                                       |

## Installation

### Copy the Example Files

Copy all of the files in `$deploy/sas-bases/examples/sas-audit/archive` to `$deploy/site-config/sas-audit`, where $deploy is the directory containing your SAS Viya platform installation files. Create the target directory, if it does not already exist.

### Update the resources.yaml File

Edit the resources.yaml file to replace the following parameters with the appropriate values.

| Parameter Name   | Description                                                                                     | Example Value |
| ---------------- | ----------------------------------------------------------------------------------------------- | ------------- |
| STORAGE-CLASS    | The storage class of the PersistentVolumeClaim. The storage class must support ReadWriteMany.   | nfs-client    |
| STORAGE-CAPACITY | The size of the PersistentVolumeClaim.                                                          | 1Gi           |

### Update the Base kustomization.yaml File

After updating the example files, you should add references to them to the base kustomization.yaml file (`$deploy/kustomization.yaml`).
* Add a reference to the resources.yaml file to the resources block.
* Add a reference to the archive-transformer.yaml file to the transformers block.

For example, if you made the changes
described above, then the base kustomization.yaml file should have entries
similar to the following:

```yaml
resources:
- site-config/sas-audit/resources.yaml
transformers:
- site-config/sas-audit/archive-transformer.yaml
```

### Build and Apply the Manifest

As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).


> **Note:** Audit service persistentvolumeclaim data does not participate in the SAS Viya platform backup and restore procedure. Therefore it contains archived data that is never restored to the SAS Viya platform system. As a result, when audit archiving is performed, SAS recommends that the cluster administrator take a backup of the audit archive data and keep that data at a secure location. Steps for backup can be found at $deploy/sas-bases/examples/sas-audit/backup/README.md