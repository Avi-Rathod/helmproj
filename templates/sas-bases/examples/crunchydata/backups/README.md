---
category: dataServer
tocprty: 16
---

# Configuration Settings for Crunchy Data pgBackRest Utility

## Overview

PostgreSQL backups play a vital role in disaster recovery. Automatically scheduled backups and backup retention policies prevent unnecessary storage accumulation and further support disaster recovery. SAS installs Crunchy Data PostgreSQL servers with automatically scheduled backups and a retention policy. This README describes how to change the configuration settings of these backups.

**Note:** The backup settings here are for the internal Crunchy Data pgBackRest utility, not for SAS Viya backup and restore utility.

## Installation

1. Copy the file `$deploy/sas-bases/examples/crunchydata/backups/crunchy-pgbackrest-backup-config-transformer.yaml` into your `$deploy/site-config/crunchydata/` directory.

2. Adjust the values in your copied file following the in-line comments.

3. Add a reference to the file in the transformers block of the base kustomization.yaml (`$deploy/kustomization.yaml`), including adding the block if it doesn't already exist:

   ```yaml
   transformers:
   - site-config/crunchydata/crunchy-pgbackrest-backup-config-transformer.yaml
   ```

**Note:** Avoid scheduling backups during times when the environment might be shut down, such as Saturday or Sunday if you regularly scale down your Kubernetes cluster on weekends.

## Additional Resources

For more information about deployment, see [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

For more information about pgBackRest, see [pgBackRest User Guide](https://pgbackrest.org/user-guide-rhel.html) and [pgBackRest Command Reference](https://pgbackrest.org/command.html).
