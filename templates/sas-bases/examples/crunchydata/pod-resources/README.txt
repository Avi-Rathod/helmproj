---
category: dataServer
tocprty: 28
---

# Configuration Settings for PostgreSQL Pod Resources

## Overview

This README describes how to adjust the CPU and memory usage of the PostgreSQL-related pods. The minimum for each of these values is described by their **request** and the maximum for each of these values is described by their **limit**.

## Installation

1. Copy the file `$deploy/sas-bases/examples/crunchydata/pod-resources/crunchy-pod-resources-transformer.yaml` into your `$deploy/site-config/crunchydata/` directory.

2. Adjust the values in your copied file following the in-line comments. As a point of reference, the SAS defaults are as follows:

   ```yaml
   # PostgreSQL values
   requests:
     cpu: 150m
     memory: 2Gi
   limits:
     cpu: 8000m
     memory: 8Gi

   # pgBackrest values
   requests:
     cpu: 100m
     memory: 256Mi
   limits:
     cpu: 1000m
     memory: 500Mi
   ```

3. Add a reference to the file in the transformers block of the base kustomization.yaml (`$deploy/kustomization.yaml`), including adding the block if it doesn't already exist:

   ```yaml
   transformers:
   - site-config/crunchydata/crunchy-pod-resources-transformer.yaml
   ```

## Additional Resources

For more information, see [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

For more information about **Pod CPU resource** configuration, go [here](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/).

For more information about **Pod memory resource** configuration, go [here](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/).
