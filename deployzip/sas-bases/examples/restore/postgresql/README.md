---
category: backupRestore
tocprty: 15
---

# Uncommon Restore Customizations

## Overview

This README file contains information about customizations that are potentially required for restoring SAS Viya Platform from a backup. These customizations are not used often.

## Custom Database Name

If the database name on the system you want to restore (the target system) does not match the database name on the system from where a backup has been taken (the source system), then you must provide
the appropriate database name as part of the restore operation.

   The database name is provided by using an environment variable, RESTORE_DATABASE_MAPPING, which should be specified in the restore job ConfigMap, sas-restore-job-parameters. Use the following command:

   ```bash
   kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/RESTORE_DATABASE_MAPPING", "value":"<source instance name>.<source database name>=<target instance name>.<target database name>" }]'
   ```

For example, if the source system has the database name "SharedServices" and the target system database is named "TestDatabase", then the environment variable would look like this:

   ```bash
   kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/RESTORE_DATABASE_MAPPING", "value":"postgres.SharedServices=postgres.TestDatabase" }]'
   ```

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. The database name is provided by using an environment variable, RESTORE_DATABASE_MAPPING, which should be specified in the restore job ConfigMap, sas-restore-job-parameters. Use the following format:

   ```yaml
   RESTORE_DATABASE_MAPPING=<source instance name>.<source database name>=<target instance name>.<target database name>
   ```

   For example, if the source system has the database name "SharedServices" and the target system database is named "TestDatabase", then the environment variable would look like this:

   ```yaml
   RESTORE_DATABASE_MAPPING=postgres.SharedServices=postgres.TestDatabase
   ```

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Configure New PostgreSQL Name

If you change the name of the PostgreSQL service during migration, you must map the new name to the old name. Edit the sas-restore-job-parameters configMap using the following command:

   ```bash
   kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/data-service-{{ NEW-SERVICE-NAME }}", "value":"{{ DIRECTORY-NAME-OF-POSTGRES-IN-BACKUP }}" }]'
   ```

To get the value for {{ NEW-SERVICE-NAME }}:

   ```bash
   kubectl -n <name-of-namespace> get dataserver -o=custom-columns=SERVICE_NAME:.spec.registrations[].serviceName --no-headers
   ```

The command lists all the PostgreSQL clusters in your deployment. Choose the appropriate one from the list. {{ DIRECTORY-NAME-OF-POSTGRES-IN-BACKUP }} is the name of the directory in backup where the
PostgreSQL backup is stored (for example, `2022-03-02T09_04_11_611_0700/acme/**postgres**`).

In the following example, {{ NEW-SERVICE-NAME }} is sas-cdspostgres, and {{ DIRECTORY-NAME-OF-POSTGRES-IN-BACKUP }} is cpspostgres:

   ```bash
      kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/data-service-sas-cdspostgres", "value":"cpspostgres" }]'
   ```

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. Edit `$deploy/kustomization.yaml` and add an entry to the restore_job_parameters configMap in the configMapGenerator section. The entry uses the following format:

   ```yaml
   data-service-{{ NEW-SERVICE-NAME }}={{ DIRECTORY-NAME-OF-POSTGRES-IN-BACKUP }}
   ```

   To get the value for {{ NEW-SERVICE-NAME }}:

   ```bash
   kubectl -n <name-of-namespace> get dataserver -o=custom-columns=SERVICE_NAME:.spec.registrations[].serviceName --no-headers
   ```

   The command lists all the PostgreSQL clusters in your deployment. Choose the appropriate one from the list.

   {{ DIRECTORY-NAME-OF-POSTGRES-IN-BACKUP }} is the name of the directory in backup where the PostgreSQL backup is stored (for example, `2022-03-02T09_04_11_611_0700/acme/**postgres**`).

   In the following example, {{ NEW-SERVICE-NAME }} is sas-cdspostgres, and {{ DIRECTORY-NAME-OF-POSTGRES-IN-BACKUP }} is cpspostgres:

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
       ...
       - data-service-sas-cdspostgres=cpspostgres
   ```

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Exclude Schemas During Restore

If you need to exclude some of the schemas during migration once, edit the sas-restore-job-parameters configMap using the following command:

   ```yaml
   kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/EXCLUDE_SCHEMAS", "value":"{{ schema1, schema2,... }}" }]'
   ```

In the following example, "dataprofiles" and "naturallanguageunderstanding" are schemas that will not be restored.

   ```bash
   kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/EXCLUDE_SCHEMAS", "value":"dataprofiles,naturallanguageunderstanding" }]'
   ```

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. Edit `$deploy/kustomization.yaml` by adding an entry to the restore_job_parameters configMap in the configMapGenerator section. The entry uses the following format:

   ```yaml
   EXCLUDE_SCHEMAS={schema1, schema2,...}
   ```

   In the following example, "dataprofiles" and "naturallanguageunderstanding" are schemas that will not be restored.

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
       ...
       - EXCLUDE_SCHEMAS=dataprofiles,naturallanguageunderstanding
   ```

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Exclude PostgreSQL Instance During Restore

If you need to exclude some of the PostgreSQL instances during restore once, edit the sas-restore-job-parameters configMap using the following command:

   ```bash
   kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/EXCLUDE_SOURCES", "value":"{{ instance1, instance2,... }}" }]'
   ```

In the following example, "sas-cdspostgres" are PostgreSQL instances that will not be restored.

   ```bash
   kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/EXCLUDE_SOURCES", "value":"sas-cdspostgres" }]'
   ```

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. Edit `$deploy/kustomization.yaml` by adding an entry to the restore_job_parameters configMap in configMapGenerator section. The entry uses the following format:

   ```yaml
   EXCLUDE_SOURCES={instance1, instance2,...}
   ```

   In the following example, "sas-cdspostgres" are PostgreSQL instances that will not be restored.

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
       ...
       - EXCLUDE_SOURCES=sas-cdspostgres
   ```

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Enable Parallel Execution for the Restore Operation

You can set a jobs option that reduces the amount of time required to restore the SAS Infrastructure Data server.
The time required to restore the database from backup is reduced by restoring the database objects over multiple parallel jobs.
The optimal value for this option depends on the underlying hardware of the server, of the client, and of the network (for example, the number of CPU cores).
Refer to the [--jobs](https://www.postgresql.org/docs/12/app-pgrestore.html "pg_restore documentation") parameter for more information about the parallel jobs.

You can specify the number of parallel jobs once using the following environment variable, which should be specified in the sas-restore-job-parameters configMap.

   ```bash
   kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/SAS_DATA_SERVER_RESTORE_PARALLEL_JOB_COUNT", "value":"{{ number-of-jobs }}" }]'
   ```

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. Specify the number of parallel jobs using the following environment variable, which should be specified in the sas-restore-job-parameters config map.

   ```yaml
   SAS_DATA_SERVER_RESTORE_PARALLEL_JOB_COUNT=<number-of-jobs>
   ```

   The following section, if not present, can be added to the kustomization.yaml file in your `$deploy` directory. If it is present, append the properties shown in this example in the `literals` section.

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
   behavior: merge
   literals:
       - SAS_DATA_SERVER_RESTORE_PARALLEL_JOB_COUNT=<number-of-jobs>
   ```

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).
