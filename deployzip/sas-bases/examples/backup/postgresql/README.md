---
category: backupRestore
tocprty: 3
---

# Configuration Settings for PostgreSQL Backup Using the SAS Viya Backup and Restore Utility

## Overview

This README describes how to revise and apply the settings for
backing up PostgreSQL using the SAS Viya Backup and Restore Utility.

## Add Additional Options for PostgreSQL Backup Command

1. If you need to add or change any option for the PostgreSQL backup command (pg_dump),
add an entry to the sas-backup-job-parameters configMap in the configMapGenerator block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - SAS_DATA_SERVER_BACKUP_ADDITIONAL_OPTIONS={{ OPTION-1-NAME OPTION-1-VALUE }},{{ FLAG-1 }},{{ OPTION-2-NAME OPTION-2-VALUE }}
   ```

   The {{ OPTION-NAME OPTION-VALUE }} and {{ FLAG }} variables should be a comma-separated list of options to be added, such as `-Z 0,--version`.

   If the sas-backup-job-parameters configMap is already present in the (`$deploy/kustomization.yaml`) file, you should add the last line only. If the configMap is not present, add the entire example.

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).
