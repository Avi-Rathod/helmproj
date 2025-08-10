---
category: dataServer
tocprty: 12
---

# Configuration Settings for PostgreSQL Replicas Count

## Overview

PostgreSQL High Availability (HA) cluster deployments have one primary database node and one or more standby database nodes. Data is replicated from the primary node to the standby node(s). In Kubernetes, a standby node is referred to as a replica. This README describes how to configure the number of replicas in a PostgreSQL HA cluster.

## Installation

1. Copy the file `$deploy/sas-bases/examples/crunchydata/replicas/crunchy-replicas-transformer.yaml` into your `$deploy/site-config/crunchydata/` directory.

2. Adjust the values in your copied file following the in-line comments.

3. Add a reference to the file in the transformers block of the base kustomization.yaml (`$deploy/kustomization.yaml`), including adding the block if it doesn't already exist:

   ```yaml
   transformers:
   - site-config/crunchydata/crunchy-replicas-transformer.yaml
   ```

## Additional Resources

For more information, see [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).
