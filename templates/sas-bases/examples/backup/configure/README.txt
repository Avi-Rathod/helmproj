---
category: backupRestore
tocprty: 2
---

# Configuration Settings for Backup Using the SAS Viya Backup and Restore Utility

## Overview

This README describes how to revise and apply the settings for
configuring backup jobs.

## Change the StorageClass for PersistentVolumeClaims Used for Storing Backups

If you want to retain the PersistentVolumeClaim (PVC) used for backup utility when the namespace is deleted,
then use a StorageClass with a ReclaimPolicy of'Retain' as the backup PVC.

1. Copy the file `$deploy/sas-bases/examples/backup/configure/sas-common-backup-data-storage-class-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. Follow the instructions in the copied sas-common-backup-data-storage-class-transformer.yaml
file to change the values in that file as necessary.

3. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/backup/sas-common-backup-data-storage-class-transformer.yaml
   ...
   ```

4. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Change the Storage Size for the `sas-common-backup-data` PersistentVolumeClaim

1. Copy the file `$deploy/sas-bases/examples/backup/configure/sas-common-backup-data-storage-size-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. Follow the instructions in the copied sas-common-backup-data-storage-size-transformer.yaml
file to change the values in that file as necessary.

3. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/backup/sas-common-backup-data-storage-size-transformer.yaml
   ...
   ```

4. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Change the Default Backup Schedule to a Custom Schedule

By default, the backup utility is run once per week on Sundays at 1:00 a.m. Use
the following instructions to schedule a backup more suited to your resources.

1. Copy the file `$deploy/sas-bases/examples/backup/configure/sas-scheduled-backup-job-change-default-backup-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. Replace {{ .Values.SCHEDULE_BACKUP_CRON_EXPRESSION }} with the cron expression for the desired schedule in the copied sas-scheduled-backup-job-change-default-backup-transformer.yaml.

3. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/backup/sas-scheduled-backup-job-change-default-backup-transformer.yaml
   ...
   ```

4. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Customize the Default Incremental Backup Schedule

By default, the incremental backup is run daily at 6:00 a.m. Use the following instructions to change the schedule of this additional job to a time more suited to your resources.

1. Copy the file `$deploy/sas-bases/examples/backup/configure/sas-scheduled-backup-incr-job-change-default-schedule.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. In the copied file, replace {{ .Values.SCHEDULE_BACKUP_CRON_EXPRESSION }} with the cron expression for the desired schedule.

3. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/backup/sas-scheduled-backup-incr-job-change-default-schedule.yaml
   ...
   ```

4. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Change the Default Schedule to Back Up All Sources to a Custom Schedule

By default, the additional job to back up all the data sources (including PostgreSQL) is suspended. When enabled, the job is scheduled to run once per week on Saturdays at 1:00 a.m by default.
Use the following instructions to change the schedule of this additional job to a time more suited to your resources.
This job should not be scheduled at the same time as `sas-scheduled-backup-job` or the `sas-scheduled-backup-incr-job`.

1. Copy the file `$deploy/sas-bases/examples/backup/configure/sas-scheduled-backup-all-sources-change-default-schedule.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. In the copied file, Replace {{ .Values.SCHEDULE_BACKUP_CRON_EXPRESSION }} with the cron expression for the desired schedule in the copied sas-scheduled-backup-all-sources-change-default-schedule.yaml.

3. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/backup/sas-scheduled-backup-all-sources-change-default-schedule.yaml
   ...
   ```

4. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Modify the Resources for the Backup Job

If the default resources are not sufficient for the completion or successful execution of the backup job, modify the resources to the values you desire.

1. Copy the file `$deploy/sas-bases/examples/backup/configure/sas-backup-job-modify-resources-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. In the copied file, replace {{ .Values.CPU_LIMIT }}with the desired value of CPU.
{{ .Values.CPU_LIMIT }}must be a non-zero and non-negative numeric value, such as "3" or "5".
You can specify fractional values for the CPUs by using decimals, such as "1.5" or "0.5".

3. In the same file, replace {{ .Values.MEMORY_LIMIT }} with the desired value of memory.
{{ .Values.MEMORY_LIMIT }} must be a non-zero and non-negative numeric value followed by "Gi". For example, "8Gi" for 8 gigabytes.

4. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/backup/sas-backup-job-modify-resources-transformer.yaml
   ...
   ```

5. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Modify the Resources of the Backup Copy and Cleanup Job

If the default resources are not sufficient for the completion or successful execution of the backup copy and cleanup job, modify the resources to the values you desire.

1. Copy the file `$deploy/sas-bases/examples/backup/configure/sas-backup-pv-copy-cleanup-job-modify-resources-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. In the copied file, replace {{ .Values.CPU_LIMIT }}with the desired value of CPU.
{{ .Values.CPU_LIMIT }}must be a non-zero and non-negative numeric value, such as "3" or "5".
You can specify fractional values for the CPUs by using decimals, such as "1.5" or "0.5".

3. In the same file, replace {{ .Values.MEMORY_LIMIT }} with the desired value of memory.
{{ .Values.MEMORY_LIMIT }} must be a non-zero and non-negative numeric value followed by "Gi". For example, "8Gi" for 8 gigabytes.

4. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/backup/sas-backup-pv-copy-cleanup-job-modify-resources-transformer.yaml
   ...
   ```

5. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Modify the Resources of the Backup Agent Container in the CAS Controller Pod

If the default resources are not sufficient for the completion or successful execution of the CAS controller pod,
modify the resources of backup agent container of CAS controller pod to the values you desire.

1. Copy the file `$deploy/sas-bases/examples/backup/configure/sas-cas-server-backup-agent-modify-resources-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. In the copied file, replace {{ .Values.CPU_LIMIT }}with the desired value of CPU.
{{ .Values.CPU_LIMIT }}must be a non-zero and non-negative numeric value, such as "3" or "5".
You can specify fractional values for the CPUs by using decimals, such as "1.5" or "0.5".

3. In the same file, replace {{ .Values.MEMORY_LIMIT }} with the desired value of memory.
{{ .Values.MEMORY_LIMIT }} must be a non-zero and non-negative numeric value followed by "Gi". For example, "8Gi" for 8 gigabytes.

4. By default the patch will be applied to all of the CAS servers. If the patch transformer is being applied to a single CAS server,
replace {{ .Values.NAME_OF_CAS_SERVER }} with the named CAS server in the same file and comment out the lines 'name: .*' and 'labelSelector: "sas.com/cas-server-default"' with a hashtag (#).

5. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/backup/sas-cas-server-backup-agent-modify-resources-transformer.yaml
   ...
   ```

6. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Change Backup Job Timeout

1. If you need to change the backup job timeout value, add an entry to the sas-backup-job-parameters configMap in the configMapGenerator block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).
The entry uses the following format, where {{ .Values.TIMEOUT_IN_MINUTES }} is an integer

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - JOB_TIME_OUT={{ .Values.TIMEOUT_IN_MINUTES }}
   ```

   If the sas-backup-job-parameters configMap is already present in the base kustomization.yaml file, you should add the last line only. If the configMap is not present, add the entire example.

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Change Backup Retention Period

1. If you need to change the backup retention period, add an entry to the sas-backup-job-parameters configMap in the configMapGenerator block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).
The entry uses the following format, where {{ .Values.RETENTION_PERIOD_IN_DAYS }} is an integer.

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - RETENTION_PERIOD={{ .Values.RETENTION_PERIOD_IN_DAYS }}
   ```

   If the sas-backup-job-parameters configMap is already present in the base kustomization.yaml file, you should add the last line only. If the configMap is not present, add the entire example.

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Back Up Additional Consul Properties

1. If you want to back up additional consul properties, keys can be added to the sas-backup-agent-parameters configMap in the base kustomization.yaml file (`$deploy/kustomization.yaml`).
To add keys, add a data block to the configMap.
If the sas-backup-agent-parameters configMap is already included in your base kustomization.yaml file, you should add the last line only. If the configMap isn't included, add the entire block.

   ```yaml
   configMapGenerator:
   - name: sas-backup-agent-parameters
     behavior: merge
     literals:
     - BACKUP_ADDITIONAL_GENERIC_PROPERTIES="{{ .Values.CONSUL_KEY_LIST }}"
   ```

   The {{ .Values.CONSUL_KEY_LIST }} should be a comma-separated list of properties to be backed up. Here is an example:

   ```yaml
   configMapGenerator:
   - name: sas-backup-agent-parameters
     behavior: merge
     literals:
     - BACKUP_ADDITIONAL_GENERIC_PROPERTIES="config/files/sas.files/maxFileSize,config/files/sas.files/blockedTypes"
   ```

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Exclude Specific Folders and Files During File System Backup

1. To exclude specific folders and files during file system backup, add an entry to the sas-backup-job-parameters configMap in the configMapGenerator block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).
If the sas-backup-job-parameters configMap is already included in your base kustomization.yaml file, you should add the last line only. If the configMap isn't included, add the entire block.

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - FILESYSTEM_BACKUP_EXCLUDELIST="{{ .Values.EXCLUDE_PATTERN }}"
   ```

   The {{ .Values.EXCLUDE_PATTERN }} should be a comma-separated list of patterns for files or folders to be excluded from the backup.
   Here is an example that excludes all the files with extensions ".tmp" or ".log":

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - FILESYSTEM_BACKUP_EXCLUDELIST="*.tmp,*.log"
   ```

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Change the Default Filter to Exclude Specific Folders and Files During File System Backup

1. By default, the filter list is set to exclude "*.lck", ".*" and "lost+found" files and folders pattern from the file system backup. To change the default filter list to exclude files and folders
during file system backup, add an entry to the sas-backup-job-parameters configMap in the
configMapGenerator block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).
If the sas-backup-job-parameters configMap is already included in your base kustomization.yaml file, you should add the last line only. If the configMap isn't included, add the entire block.

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - FILESYSTEM_BACKUP_OVERRIDE_EXCLUDELIST="{{ .Values.EXCLUDE_PATTERN }}"
   ```

   The {{ .Values.EXCLUDE_PATTERN }} should be a comma-separated list of patterns for files or folders to be excluded from the backup.
   Here is an example that excludes all the files with extensions ".tmp" or ".log":

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - FILESYSTEM_BACKUP_OVERRIDE_EXCLUDELIST="*.tmp,*.log"
   ```

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Disable Backup Job Failure Notification

1. By default, you are notified if the backup job fails. To disable backup job failure notification, add an entry to the sas-backup-job-parameters configMap in the configMapGenerator block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). Replace {{ .Values.ENABLE_NOTIFICATIONS }} with the string "false".

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - ENABLE_NOTIFICATIONS={{ .Values.ENABLE_NOTIFICATIONS }}
   ```

   If the sas-backup-job-parameters configMap is already present in the base kustomization.yaml file, add the last line only. If the configMap is not present, add the entire example.

   To restore the default, change the value of {{ .Values.ENABLE_NOTIFICATIONS }} from "false" to "true".

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Include or Exclude All Registered PostgreSQL Servers from Backup

1. To include or exclude all Postgres servers registered with SAS Viya in the default back up, add the INCLUDE_POSTGRES variable to sas-backup-job-parameters configMap in the configMapGenerator
block of the base kustomization.yaml file ($deploy/kustomization.yaml). If the sas-backup-job-parameters configMap is already present in the base kustomization.yaml file, you should add the last line only.
If the configMap is not present, add the entire example.

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - INCLUDE_POSTGRES="{{ .Values.INCLUDE_POSTGRES }}"
   ```

2. To include all the registered PostgreSQL servers, replace {{ .Values.INCLUDE_POSTGRES }} in the code with a value 'true'.
To exclude all the registered PostgreSQL servers, replace {{ .Values.INCLUDE_POSTGRES }} in the code with a value 'false'.

3. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Modify the fsGroup Resources of the Backup and Restore Jobs

If using the default fsGroup settings does not result in the completion or successful execution of the backup job, modify the fsGroup resources to the values you desire.

1. Copy the file `$deploy/sas-bases/examples/backup/configure/sas-backup-job-modify-fsgroup-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/backup`.

2. Follow the instructions in the copied sas-backup-job-modify-fsgroup-transformer.yaml
file to change the values in that file as necessary.

3. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/backup/sas-backup-job-modify-fsgroup-transformer.yaml
   ...
   ```

4. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Disable Resource Validation

By default, resources such as space available for a PVC are pre-validated against PVC capacity to store data for a backup job. You can disable the resource validations for backup job if necessary.

### Disable the resource validation temporarily

Add an entry to the sas-backup-job-parameters configMap with the following command.

```bash
kubectl patch cm sas-backup-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/DISABLE_VALIDATION", "value":"true" }]'
```

### Disable the resource validations permanently

1. Add an entry to the sas-backup-job-parameters configMap in the configMapGenerator block of the base kustomization.yaml file.

   ```yaml
   configMapGenerator:
   - name: sas-backup-job-parameters
     behavior: merge
     literals:
     - DISABLE_VALIDATION="true"
   ```

   If the sas-backup-job-parameters configMap is already present in the base kustomization.yaml file, add the last line only. If the configMap is not present, add the entire example.

2. Build and apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).
