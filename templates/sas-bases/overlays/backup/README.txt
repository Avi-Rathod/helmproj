---
category: backupRestore
tocprty: 4
---

# Optional Configurations for Backup Jobs

## Enable a Suspended Incremental Backup Job

To enable a suspended incremental backup job, edit the base kustomization file (`$deploy/kustomization.yaml`).

1. In the transformers block, add `/sas-bases/overlays/backup/sas-scheduled-backup-incr-job-enable.yaml`. Here is an example:

   ```yaml
   ...
   transformers:
   - sas-bases/overlays/backup/sas-scheduled-backup-incr-job-enable.yaml
   ...
   ```

   The above transformer also sets INCLUDE_POSTGRES=False in sas-backup-job-parameters configmap.

2. Build and Apply the Manifest
   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Enable a Suspended Job to Back Up All the Sources

To enable a suspended job to back up all sources (including PostgreSQL), edit the base kustomization file (`$deploy/kustomization.yaml`).

1. In the transformers block, add `/sas-bases/overlays/backup/sas-scheduled-backup-all-sources-enable.yaml`. Here is an example:

   ```yaml
   ...
   transformers:
   - sas-bases/overlays/backup/sas-scheduled-backup-all-sources-enable.yaml
   ...
   ```

2. Build and Apply the Manifest
   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).
