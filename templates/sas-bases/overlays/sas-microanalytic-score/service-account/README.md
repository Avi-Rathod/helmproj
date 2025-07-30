---
category: SAS Micro Analytic Service
tocprty: 5
---

# Configure SAS Micro Analytic Service to Grant Security Context Constraints to Its Service Account

## Overview

This README describes how privileges can be added to the sas-microanalytic-score pod service account. Security context constraints are required in an OpenShift cluster if the sas-micro-analytic-score pod needs to mount an NFS volume. If the Python environment is made available through an NFS mount, the service account requires NFS volume mounting privileges.

**Note:** For information about using NFS to make Python available, see the README file at `/$deploy/sas-bases/examples/sas-open-source-config/python/README.md` (for Markdown format) or `/$deploy/sas-bases/docs/configure_python_for_sas_viya.htm` (for HTML format).

## Prerequisites

### Granting Security Context Constraints on an OpenShift Cluster

The `/$deploy/sas-bases/overlays/sas-microanalytic-score/service-account` directory contains a file to grant security context constraints for using NFS on an OpenShift cluster.

A Kubernetes cluster administrator should add these security context constraints to their OpenShift cluster prior to deploying the SAS Viya platform. Use one of the following commands:

```yaml
kubectl apply -f sas-microanalytic-score-scc.yaml
```

or

```yaml
oc create -f sas-microanalytic-score-scc.yaml
```

### Bind the Security Context Constraints to a Service Account

After the security context constraints have been applied, you must link the security context constraints to the appropriate service account that will use it. Use the following command:

```yaml
oc -n {{ NAME-OF-NAMESPACE }} adm policy add-scc-to-user sas-microanalytic-score -z sas-microanalytic-score
```

## Post-Installation Tasks

### Restart sas-microanalytic-score Service Pod

1. Run this command to restart pod with new privileges added to the service account:

   ```sh
   kubectl rollout restart deployment sas-microanalytic-score -n <name-of-namespace>
   ```