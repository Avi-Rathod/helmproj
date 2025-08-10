---
category: SAS Viya File Service
tocprty: 20
---

# Configure SAS Viya File Service for Azure Blob Storage

This README describes the steps necessary to configure the SAS Viya platform files service to use Azure Blob Storage
as the back end for file content.

## Prerequisites

Before you start, create or obtain a storage account and record the name of the storage account and its access key.

Follow the instructions in the "Change Alternate Data Storage for SAS Viya Platform Files Service"
README file to make Azure Blob Storage the database for storing file content. The README
file is located at `$deploy/sas-bases/overlays/sas-files/README.md`
(for Markdown format) or `$deploy/sas-bases/docs/change_alternate_data_storage_for_sas_viya_file_service.htm`
(for HTML format).

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-files/azure/blob` directory to the
`$deploy/site-config/sas-files/azure/blob` directory. Create the target directory if it does
not already exist.

2. Create a file named `account_key` in the `$deploy/site-config/sas-files/azure/blob`
directory, and paste the storage account key into the file. The file should
only contain the storage account key.

3. In the `$deploy/site-config/sas-files/azure/blob/configmaps.yaml` file, replace
`{{ .Values.STORAGE_ACCOUNT_NAME }}` with the name of the storage account to be used by
the files service.

4. Make the following changes to the base kustomization.yaml file in the `$deploy`
directory.

* Add `site-config/azure/blob` to the resources block. Here is an example:

   ```yaml
   resources:
   ...
   - site-config/sas-files/azure/blob
   ...
   ```

* Add `site-config/azure/blob/transformers.yaml` to the transformers block. Here
is an example:

   ```yaml
   transformers:
   ...
   - site-config/sas-files/azure/blob/transformers.yaml
   ...
   ```

5. Use the deployment commands described in [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm) to apply the new settings.