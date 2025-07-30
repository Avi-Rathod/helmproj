---
category: backupRestore
tocprty: 18
---

# Configure Restore Job Parameters for SAS Model Repository Service

## Overview

The SAS Model Repository service provides support for registering, organizing,
and managing models within a common model repository. This service is used by
SAS Event Stream Processing, SAS Intelligent Decisioning, SAS Model Manager,
Model Studio, SAS Studio, and SAS Visual Analytics.

Analytic store (ASTORE) files are extracted from the analytic store's CAS table
in the ModelStore caslib and written to the ASTORES persistent volume, when the
following actions are performed:

- an analytic store model is set as the project champion model using SAS Model
  Manager
- an analytic store model is published to a SAS Micro Analytic Service
  publishing destination from SAS Model Manager or Model Studio
- a test is run for a decision that contains an analytic store model using SAS
  Intelligent Decisioning

When Python models (or decisions that use Python models) are published to the
SAS Micro Analytic Service or CAS, the Python score resources are copied to the
ASTORES persistent volume. Score resources for project champion models that are
used by SAS Event Stream Processing are also copied to the persistent volume.

During the migration process, the analytic stores models and Python models are
restored in the common model repository, along with their associated resources
and analytic store files in the ASTORES persistent volume.

**Note:** The Python score resources from a SAS Viya 3.5 to SAS Viya 4
environment are not migrated with the SAS Model Repository service. For more
information, see
[Promoting and Migrating Content](http://documentation.sas.com/?cdcId=mdlmgrcdc&cdcVersion=default&docsetId=mdlmgrag&docsetTarget=p0n2f2djoollgqn13isibmb98qd2.htm)
in _SAS Model Manager: Administrator's Guide_.

This README describes how to make the restore job parameters available to the
sas-model-repository container within your deployment, as part of the backup and
restore process. The restore process is performed during start-up of the
sas-model-repository container, if the `SAS_DEPLOYMENT_START_MODE` parameter is
set to `RESTORE` or `MIGRATION`.

## Prerequisites

No prerequisite steps are required.

## Installation

1. Copy the files in the
   `$deploy/sas-bases/examples/sas-model-repository/restore` directory to the
   `$deploy/site-config/sas-model-repository/restore` directory. Create the
   target directory, if it does not already exist.

2. Make a copy of the kustomization.yaml file to recover after temporary changes
   are made: cp kustomization.yaml kustomization.yaml.save

3. Add site-config/sas-model-repository/restore/restore-transformer.yaml to the
   transformers block of the base kustomization.yaml file in the `$deploy`
   directory.

   ```yaml
   transformers:
     - site-config/sas-model-repository/restore/restore-transformer.yaml
   ```

   Excerpt from the restore-transformer.yaml file:

   ```yaml
   patch: |-
     # Add restore job parameters
     - op: add
       path: /spec/template/spec/containers/0/envFrom/-
       value:
       configMapRef:
       name: sas-restore-job-parameters
   ```

4. Add the sas-restore-job-parameters code below to the configMapGenerator
   section of kustomization.yaml, and remove the `configMapGenerator` line, if
   it is already present in the default kustomization.yaml:

   ```yaml
   configMapGenerator:
     - name: sas-restore-job-parameters
       behavior: merge
       literals:
         - SAS_BACKUP_ID={{ SAS-BACKUP-ID-VALUE }}
         - SAS_DEPLOYMENT_START_MODE=RESTORE
   ```

   Here are more details about the previous code.

   - Replace the value for `{{SAS-BACKUP-ID-VALUE}}` with the ID of the backup
     that is selected for restore.
   - To increase the logging levels, add the following line to the literals
     section:
     - SAS_LOG_LEVEL=DEBUG

   For more information, see
   [Backup and Restore: Perform a Restore](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=calbr&docsetTarget=n1607whucnyc02n1eo6tbvl1tzcs.htm)
   in _SAS Viya Platform Operations_.

5. If you need to rerun a migration, you must remove the `RestoreBreadcrumb.txt`
   file from the `/models/resources/viya` directory.

   Here is example code for removing the file:

   ```console
   kubectl get pods -n <namespace> | grep model-repository
   kubectl exec -it -n <namespace> <podname> -c sas-model-repository -- bash
   rm /models/resources/viya/RestoreBreadcrumb.txt
   ```

6. Complete the deployment steps to apply the new settings. See
   [Deploy the Software](<(http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm)>)
   in _SAS Viya Platform: Deployment Guide_.

   **Note:** This overlay can be applied during the initial deployment of the
   SAS Viya platform or after the deployment of the SAS Viya platform.

   - If you are applying the overlay during the initial deployment of the SAS
     Viya platform, complete all the tasks in the README files that you want to
     use, then run `kustomize build` to create and apply the manifests.
   - If the overlay is applied after the initial deployment of the SAS Viya
     platform, run `kustomize build` to create and apply the manifests.

## Additional Resources

- [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
- [SAS Viya Platform: Models Administration](http://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calmodels)
- [SAS Model Manager: Administrator's Guide](http://documentation.sas.com/?cdcId=mdlmgrcdc&cdcVersion=default&docsetId=mdlmgrag)
