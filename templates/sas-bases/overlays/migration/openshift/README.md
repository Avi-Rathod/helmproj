---
category: migration
tocprty: 8
---

# Granting Security Context Constraints for Migration on an OpenShift Cluster

## Overview

The `$deploy/sas-bases/overlays/migration/openshift` directory contains a file to grant security context constraints (SCCs) for the sas-migration-job pod on an OpenShift cluster.
**Note:** The security context constraint needs to be applied only if the backup is present on an NFS path.

## Installation

1. Use one of the following commands to apply the SCCs.

```sh
# using kubectl
kubectl apply -f migration-job-scc.yaml

# using the OpenShift CLI
oc create -f migration-job-scc.yaml
```

1. Use the following command to link the SCCs to the appropriate Kubernetes service account.
Replace the entire variable {{ NAME-OF-NAMESPACE }}, including the braces, with the Kubernetes namespace used for SAS Viya.

```sh
oc -n {{ NAME-OF-NAMESPACE }} adm policy add-scc-to-user sas-migration-job -z sas-viya-backuprunner
```
