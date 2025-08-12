---
category: backupRestore
tocprty: 13
---

# Configuration Settings for Restore Using the SAS Viya Backup and Restore Utility

## Overview

This README describes how to revise and apply the settings for configuring restore jobs.

## Change Restore Job Timeout

To change the restore job timeout value temporarily, edit the sas-restore-job-parameters configMap using the following command, where {{ TIMEOUT-IN-MINUTES }} is an integer.

```bash
kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[ {"op": "replace", "path": "/data/JOB_TIME_OUT", "value":"{{ TIMEOUT-IN-MINUTES }}" }]'
```

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. To change the restore job timeout value, edit the `$deploy/kustomization.yaml` file by adding an entry for the sas-restore-job-parameters configMap in the configMapGenerator block.
The entry uses the following format, where {{ TIMEOUT-IN-MINUTES }} is an integer.

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
     - JOB_TIME_OUT={{ TIMEOUT-IN-MINUTES }}
   ```

   If the sas-restore-job-parameters configMap is already present in the base kustomization.yaml file, you should add the last line only. If the configMap is not present,
   add the entire example.

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Filter Configuration Definition Properties

To skip the restore of the configuration definition properties once, edit the sas-restore-job-parameters configMap using the following command.

```bash
kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/RESTORE_DEFINITION_FILTER", "value":"{{ RESTORE-DEFINITION-FILTER-CSV }}" }]'
```

The {{ RESTORE-DEFINITION-FILTER-CSV }} is a json string containing the comma-separated list of 'key:value' pairs where the key is in the form 'serviceName.definitionName.version'
and the value can be a comma-separated list of properties to be filtered. If the entire definition is to be excluded,
then set the value to '*'. If the service name is not present
in the definition, then only provide 'definitionName'. Each key and value must be enclosed in double quotes ("). Here is an example:

```bash
kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/RESTORE_DEFINITION_FILTER", "value":"{\"sas.dataserver.common.1\":\"*\",\"deploymentBackup.sas.deploymentbackup.1\":\"*\",\"deploymentBackup.sas.deploymentbackup.2\":\"*\",\"deploymentBackup.sas.deploymentbackup.3\":\"*\",\"sas.security.1\":\"*\",\"vault.sas.vault.1\":\"*\",\"vault.sas.vault.2\":\"*\",\"SASDataExplorer.sas.dataexplorer.1\":\"*\",\"SASLogon.sas.logon.sas9.1\":\"*\",\"sas.cache.1\":\"*\",\"sas.cache.2\":\"*\",\"sas.cache.3\":\"*\",\"sas.cache.4\":\"*\",\"identities-SASLogon.sas.identities.providers.ldap.user.1\":\"accountId,address.country\",\"SASLogon.sas.logon.saml.providers.external_saml.1\":\"assertionConsumerIndex,idpMetadata\"}" }]'
```

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. Edit the `$deploy/kustomization.yaml` file by adding an entry for the sas-restore-job-parameters configMap in the configMapGenerator block. The entry uses the following format.

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
     - RESTORE_DEFINITION_FILTER={{ RESTORE-DEFINITION-FILTER-CSV }}
   ```

   The {{ RESTORE-DEFINITION-FILTER-CSV }} is a json string containing the comma-separated list of 'key:value' pairs where key is in the form 'serviceName.definitionName.version'
   and value itself can be a comma-separated list of properties to be filtered. If entire definition is to be excluded, then set the value to '*'. If service name is not present in
   the definition then only provide 'definitionName'. Each key and value must be enclosed in double quotes ("). Here is an example:

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
     - RESTORE_DEFINITION_FILTER='{"sas.dataserver.common.1":"*","deploymentBackup.sas.deploymentbackup.1":"*","deploymentBackup.sas.deploymentbackup.2":"*","deploymentBackup.sas.deploymentbackup.3":"*","sas.security.1":"*","vault.sas.vault.1":"*","vault.sas.vault.2":"*","SASDataExplorer.sas.dataexplorer.1":"*","SASLogon.sas.logon.sas9.1":"*","sas.cache.1":"*","sas.cache.2":"*","sas.cache.3":"*","sas.cache.4":"*","identities-SASLogon.sas.identities.providers.ldap.user.1":"accountId,address.country","SASLogon.sas.logon.saml.providers.external_saml.1":"assertionConsumerIndex,idpMetadata"}'
   ```

   If the sas-restore-job-parameters configMap is already present in the base kustomization.yaml file, you should add the last line only. If the configMap is not present, add the entire example.

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Filter Configuration Properties

To skip the restore of the configuration properties once, edit  the sas-restore-job-parameters configMap using the following command.

```bash
kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/RESTORE_CONFIGURATION_FILTER", "value":"{{ RESTORE-CONFIGURATION-FILTER-CSV }}" }]'
```

The {{ RESTORE-CONFIGURATION-FILTER-CSV }} is a json string containing the comma-separated list of 'key:value' pairs where the key is in the form 'serviceName.configurationMediaType' and the value can
be a comma-separated list of properties to be filtered.
If the entire configuration is to be excluded, then set the value to '*'.
If the service name is not present in the configuration, then use the media type. Each key and value must be enclosed in double quotes ("). Here is an example:

```bash
kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/RESTORE_DEFINITION_FILTER", "value":"{\"postgres.application/vnd.sas.configuration.config.sas.dataserver.conf+json;version=1\":\"*\",\"maps-reportPackages-webDataAccess.application/vnd.sas.configuration.config.sas.maps+json;version=2\":\"useArcGISOnlineMaps,localEsriServicesUrl\"}" }]'
```

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. Edit the `$deploy/kustomization.yaml` file by adding an entry for the sas-restore-job-parameters configMap in the configMapGenerator block. The entry uses the following format.

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
     - RESTORE_CONFIGURATION_FILTER={{ RESTORE-CONFIGURATION-FILTER-CSV }}
   ```

   The {{ RESTORE-CONFIGURATION-FILTER-CSV }} is a json string containing the comma-separated list of 'key:value' pairs where key is in the form 'serviceName.configurationMediaType' and value itself
   can be a comma-separated list of properties to be filtered. If the entire configuration is to be excluded, then set the value to '*'. If service name is not present in the configuration, then use
   the media type. Each key and value must be enclosed in double quotes ("). Here is an example:

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
     - RESTORE_CONFIGURATION_FILTER='{"postgres.application/vnd.sas.configuration.config.sas.dataserver.conf+json;version=1":"*","maps-reportPackages-webDataAccess.application/vnd.sas.configuration.config.sas.maps+json;version=2":"useArcGISOnlineMaps,localEsriServicesUrl"}'
   ```

   If the sas-restore-job-parameters configMap is already present in the base kustomization.yaml file, you should add the last line only. If the configMap is not present, add the entire example.

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Disable Restore Job Failure Notification

By default, you are notified if the restore job fails. To disable the restore job failure notification once,
add an entry to the sas-restore-job-parameters configMap with the following command. Replace {{ ENABLE-NOTIFICATIONS }} with the string "false".

```bash
kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/ENABLE_NOTIFICATIONS", "value":"{{ ENABLE-NOTIFICATIONS }}" }]'
```

To restore the default, change the value of {{ ENABLE-NOTIFICATIONS }} from "false" to "true".

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. Add an entry to the sas-restore-job-parameters configMap in the configMapGenerator block of the base kustomization.yaml file. Replace {{ ENABLE-NOTIFICATIONS }} with the string "false".

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
     - ENABLE_NOTIFICATIONS={{ ENABLE-NOTIFICATIONS }}
   ```

   If the sas-restore-job-parameters configMap is already present in the base kustomization.yaml file, add the last line only. If the configMap is not present, add the entire example.

   To restore the default, change the value of {{ ENABLE-NOTIFICATIONS }} from "false" to "true".

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Modify the Resources of the Restore Job

In some cases, the default resources may not be sufficient for completion or successful execution of the restore job,
resulting in the pod status being marked as OOMKilled. In this case, modify the resources to the values you desire.

Replace {{ CPU-LIMIT }} with the desired value of CPU. {{ CPU-LIMIT }} must be a non-zero and non-negative numeric value, such as "3" or "5".
You can specify fractional values for the CPUs by using decimals, such as "1.5" or "0.5".

```bash
   kubectl patch cronjob sas-restore-job -n name-of-namespace --type json -p '[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/resources/limits/cpu", "value":"{{ CPU-LIMIT }}" }]'
```

Replace {{ MEMORY-LIMIT }} with the desired value for memory. {{ MEMORY-LIMIT }} must be a non-zero and non-negative numeric value followed by "Gi". For example, "8Gi" for 8 gigabytes.

   ```bash
      kubectl patch cronjob sas-restore-job -n name-of-namespace --type json -p '[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/resources/limits/memory", "value":"{{ MEMORY-LIMIT }}" }]'
   ```

If you are running the restore job with this configuration frequently, then add this configuration permanently using the following method.

1. Copy the file `$deploy/sas-bases/examples/restore/configure/sas-restore-job-modify-resources-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/restore`.

2. In the copied file, replace {{ CPU-LIMIT }} with the desired value of CPU.
{{ CPU-LIMIT }} must be a non-zero and non-negative numeric value, such as "3" or "5".
You can specify fractional values for the CPUs by using decimals, such as "1.5" or "0.5".

3. In the same file, replace {{ MEMORY-LIMIT }} with the desired value of memory.
{{ MEMORY-LIMIT }} must be a non-zero and non-negative numeric value followed by "Gi". For example, "8Gi" for 8 gigabytes.

4. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/restore`, you would modify the
base kustomization.yaml file like this:

   ```yaml
   ...
   transformers:
   ...
   - site-config/restore/sas-restore-job-modify-resources-transformer.yaml
   ...
   ```

5. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).

## Switch PostgreSQL Server Hosts After Restore Without SQL Proxy

External PostgreSQL servers can be backed up and restored externally. Point in time recovery performed in such cases creates a new PostgreSQL server with a new host name.
To automatically update the host names of the PostgreSQL server after the restore is completed using the SAS Viya Backup and Restore Utility,
update the sas-restore-job-parameters config map with the following parameters before performing the restore.

* AUTO_SWITCH_POSTGRES: "true"

* DATASERVER_HOST_MAP: "{{ DATASERVER_HOST_MAP }}"

   {{ DATASERVER_HOST_MAP }} is comma-separated list of key value pairs that describes the mapping of dataserver custom resource to updated host names.
   The key and value within each KV pair is separated by colon (:).
   Here is an example that switches the host names for SAS platform PostgreSQL and SAS CDS PostgreSQL servers with the new host names:

   `DATASERVER_HOST_MAP="sas-platform-postgres:restored-postgres.postgres.azure.com,sas-cds-postgres:restored-cds-postgres.postgres.azure.com"`

Here is an example command that adds the AUTO_SWITCH_POSTGRES_HOST and DATASERVER_HOST_MAP parameters to the config map:

```bash
kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/AUTO_SWITCH_POSTGRES_HOST", "value":"TRUE" }, {"op": "replace", "path": "/data/DATASERVER_HOST_MAP","value":"sas-platform-postgres:restored-postgres.postgres.azure.com,sas-cds-postgres:restored-cds-postgres.postgres.azure.com" }]'
```

## Switch PostgreSQL Server Hosts After Restore With SQL Proxy

This section is used when SQL proxy is used to interface the external PostgreSQL server. External PostgreSQL servers can be backed up and restored externally.
Point in time recovery performed in such cases creates a new PostgreSQL server with a new host name.
To automatically update the host names of the PostgreSQL server after the restore is completed using the SAS Viya Backup and Restore Utility,
update the sas-restore-job-parameters config map with the following parameters before performing the restore.

* AUTO_SWITCH_POSTGRES: "true"

* SQL_PROXY_POSTGRES_CONNECTION_MAP: "{{ SQL_PROXY_POSTGRES_CONNECTION_MAP }}"

   {{ SQL_PROXY_POSTGRES_CONNECTION_MAP }} is comma-separated list of key value pairs that describes the mapping of the SQL proxy Kubernetes deployment name to new PostgreSQL connection string.
   The key and value within each KV pair is separated by the first colon (:).
   Here is an example that switches the host names for SAS platform PostgreSQL and SAS CDS PostgreSQL servers with the new connection strings:

   `SQL_PROXY_POSTGRES_CONNECTION_MAP="platform-postgres-sql-proxy:sub7:us-east1:restored-postgres-default-pgsql-clone,cds-postgres-sql-proxy:restored-cds-postgres-default-pgsql-clone"`

Here is an example command that adds the AUTO_SWITCH_POSTGRES_HOST and SQL_PROXY_POSTGRES_CONNECTION_MAP parameters to the config map:

```bash
kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/AUTO_SWITCH_POSTGRES_HOST", "value":"TRUE" }, {"op": "replace", "path": "/data/SQL_PROXY_POSTGRES_CONNECTION_MAP","value":"platform-postgres-sql-proxy:sub7:us-east1:restored-postgres-default-pgsql-clone,cds-postgres-sql-proxy:restored-cds-postgres-default-pgsql-clone" }]'
```

## Disable Resource Validations

By default, resources like CPU and memory are pre-validated in order for the restore job to be completed successfully.
You can disable the resource validation to complete the restore job successfully

### Disable Resource Validations Temporarily

Add an entry to the sas-restore-job-parameters configMap with the following command.

```bash
kubectl patch cm sas-restore-job-parameters-name -n name-of-namespace --type json -p '[{"op": "replace", "path": "/data/DISABLE_VALIDATION", "value":"true" }]'
```

### Disable Resource Validation Permanently

1. Add an entry to the sas-restore-job-parameters configMap in the configMapGenerator block of the base kustomization.yaml file.

   ```yaml
   configMapGenerator:
   - name: sas-restore-job-parameters
     behavior: merge
     literals:
     - DISABLE_VALIDATION="true"
   ```

   If the sas-restore-job-parameters configMap is already present in the base kustomization.yaml file, add the last line only. If the configMap is not present, add the entire example.

2. Build and Apply the Manifest

   As an administrator with cluster permissions, apply the edited files to your deployment by performing the steps described in [Modify Existing Customizations in a Deployment](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n1f2q6pp0gjheqn1jl204vptrubs.htm).
