---
category: SAS Viya File Service
tocprty: 3
---

# Change Alternate Data Storage for SAS Viya Platform Files Service

## Overview

The SAS Viya platform files service uses PostgreSQL to store file metadata and content. However, PostgreSQL is unable to store large files. To overcome this limitation and make SAS Viya platform files service scalable, you can choose to store the file content in other data storage, such as Azure Blob Storage.
If you choose Azure Blob Storage as the storage database, then the file content is stored in Azure Blob Storage and file metadata remains in PostgreSQL.

The directory `$deploy/sas-bases/overlays/sas-files` contains an overlay to customize your SAS Viya deployment to make Azure Blob Storage the database for storing file content.

## Instructions

1. Edit the base kustomization.yaml file (`$deploy/kustomization.yaml`) to add the following entries for generating the ConfigMap and adding a ConfigMap reference.

* In the resources block, add `sas-bases/overlays/sas-files`. Here is an example:

   ```yaml
   resources:
   ...
   - sas-bases/overlays/sas-files
   ...
   ```

* In the transformers block, add `sas-bases/overlays/sas-files/file-custom-db-transformer.yaml`. Here is an example:

   ```yaml
   transformers:
   ...
   - sas-bases/overlays/sas-files/file-custom-db-transformer.yaml
   ...
   ```

2. Follow the instructions in the "Configure SAS Viya Platform Files Service for Azure Blob
Storage" README file to configure the files service. The README file is
located at `$deploy/sas-bases/examples/sas-files/azure/blob/README.md` (for Markdown format)
or at `$ deploy/sas-bases/docs/configure_sas_viya_file_service_for_azure_blob_storage.htm`
(for HTML format).