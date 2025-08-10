---
category: dataServer
tocprty: 8
---

# Configuration Settings for PostgreSQL Database Tuning

## Overview

PostgreSQL is highly configurable, allowing you to tune the server(s) to meet expected workloads. This README describes how to tune and adjust the configuration for your PostgreSQL clusters. Here are the transformers in `$deploy/sas-bases/examples/crunchydata/tuning/` with a description of the purpose of each:
- crunchy-tuning-connection-params-transformer.yaml: Change PostgreSQL connection parameters
- crunchy-tuning-log-params-transformer.yaml: Change PostgreSQL log parameters
- crunchy-tuning-patroni-params-transformer.yaml: Change Patroni parameters
- crunchy-tuning-pg-hba-no-tls-transformer.yaml: Set the entry for the pg_hba.conf file to disable TLS


## Installation

1. Copy the transformer file (for example, `$deploy/sas-bases/examples/crunchydata/tuning/crunchy-tuning-connection-params-transformer.yaml`) into your `$deploy/site-config/crunchydata/`.

2. Rename the copied file to something unique. For example, the above transformer targeting Platform PostgreSQL could be named as `platform-postgres-crunchy-tuning-connection-params-transformer.yaml`.

3. Adjust the values in your copied file using the in-line comments of the file and the directions in "Customize the Configuration Settings" below.

4. Add a reference to the file in the transformers block of the base kustomization.yaml (`$deploy/kustomization.yaml`). The following example uses an example transformer file named `platform-postgres-crunchy-tuning-connection-params-transformer.yaml`:

   ```yaml
   transformers:
   - site-config/crunchydata/platform-postgres-crunchy-tuning-connection-params-transformer.yaml
   ```

## Customize the Configuration Settings

### Change PostgreSQL Configuration Parameters

To change the PostgreSQL parameters, such as a log filename with a timestamp instead of the name of the week, use the crunchy-tuning-log-params-transformer.yaml file as a sample transformer. You can add, remove, or update log parameters and their values following the pattern shown in the sample file. For the complete list of available PostgreSQL configuration parameters, see [PostgreSQL Server Configuration](https://www.postgresql.org/docs/12/config-setting.html).

### PostgreSQL HBA Setting to Disable TLS

Deployments that use non-TLS or Front-Door TLS can use the crunchy-tuning-pg-hba-no-tls-transformer.yaml file to make the incoming client connections go through without TLS.

## Additional Resources

[SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en)

[PostgreSQL Client Host-Based Authentication](https://www.postgresql.org/docs/12/auth-pg-hba-conf.html)
