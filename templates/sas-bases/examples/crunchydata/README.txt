---
category: dataServer
tocprty: 4
---

# Configure Crunchy Data PostgreSQL

## Overview

Internally managed instances of PostgreSQL use the [PostgreSQL Operator and Containers](https://github.com/crunchydata) provided by [Crunchy Data](https://www.crunchydata.com/) behind the scenes to create the PostgreSQL servers.

## Prerequisites

Before installing any Crunchy Data components, you should know which PostgreSQL servers are required by your SAS Viya platform order.

Additionally, you should have followed the steps to configure PostgreSQL in the SAS Viya platform described in the "Configure PostgreSQL" README located at `$deploy/sas-bases/examples/postgres/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configure_postgresql.htm` (for HTML format).

## Installation

You must install the Crunchy Data PostgreSQL Operator in conjunction with specific PostgreSQL servers.

To install the PostgreSQL Operator, go to the base kustomization.yaml file (`$deploy/kustomization.yaml`). In the resources block of that file, add the following content, including adding the block if it doesn't already exist:

```yaml
resources:
- sas-bases/overlays/crunchydata/postgres-operator
```

Additionally, you must add content to the components block based on whether you are deploying Platform PostgreSQL or CDS PostgreSQL.

### Internal Platform PostgreSQL

Go to the base kustomization.yaml file (`$deploy/kustomization.yaml`). In the components block of that file, add the following content, including adding the block if it doesn't already exist:

```yaml
components:
- sas-bases/components/crunchydata/internal-platform-postgres
```

**Note**: The internal-platform-postgres entry should be listed before any entries that do not relate to Crunchy Data.

### Internal Common Data Store (CDS) PostgreSQL

Go to the base kustomization.yaml file (`$deploy/kustomization.yaml`). In the components block of that file, add the following content, including adding the block if it doesn't already exist:

```yaml
components:
- sas-bases/components/crunchydata/internal-cds-postgres
```

**Note**: The internal-cds-postgres entry should be listed before any entries that do not relate to Crunchy Data.

## Examples

Crunchy Data supports many PostgreSQL features and configurations. Here are the supported options:

* Automated backups of PostgreSQL data. See the "Configuration Settings for PostgreSQL Backups" README located at `$deploy/sas-bases/examples/crunchydata/backups/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configuration_settings_for_crunchy_data_pgbackrest_utility.htm` (for HTML format)
* Resource allocation for PostgreSQL pods. See the "Configuration Settings for PostgreSQL Pod Resources" README located at `$deploy/sas-bases/examples/crunchydata/pod-resources/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configuration_settings_for_postgresql_pod_resources.htm` (for HTML format)
* PostgreSQL replicas for high availability. See the "Configuration Settings for PostgreSQL Replicas Count" README located at `$deploy/sas-bases/examples/crunchydata/replicas/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configuration_settings_for_postgresql_replicas_count.htm` (for HTML format)
* Kubernetes storage options for PostgreSQL data volumes. See the "Configuration Settings for PostgreSQL Storage" README located at `$deploy/sas-bases/examples/crunchydata/storage/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configuration_settings_for_postgresql_storage.htm` (for HTML format)
* PostgreSQL configuration and tuning. See the "Configuration Settings for PostgreSQL Database Tuning" README located at `$deploy/sas-bases/examples/crunchydata/tuning/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configuration_settings_for_postgresql_database_tuning.htm` (for HTML format)
