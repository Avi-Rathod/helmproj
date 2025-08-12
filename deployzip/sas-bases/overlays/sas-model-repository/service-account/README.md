---
category: SAS Model Repository Service
tocprty: 5
---

# Configure SAS Model Repository Service to Add Service Account

## Overview

This README describes how a service account with defined privileges can be added
to the sas-model-repository pod. A service account is required in an OpenShift
cluster if it needs to mount NFS. If the Python environment is made available
through an NFS mount, the service account requires NFS volume mounting
privilege.

**Note:** For information about using NFS to make Python available, see the
README file at
`/$deploy/sas-bases/examples/sas-open-source-config/python/README.md` (for
Markdown format) or `/$deploy/sas-bases/docs/configure_python_for_sas_viya.htm`
(for HTML format).

## Prerequisites

### Granting Security Context Constraints on an OpenShift Cluster

The `/$deploy/sas-bases/overlays/sas-model-repository/service-account` directory
contains a file to grant security context constraints for using NFS on an
OpenShift cluster.

A Kubernetes cluster administrator should add these security context constraints
to their OpenShift cluster prior to deploying the SAS Viya platform. Use one of
the following commands:

```yaml
kubectl apply -f sas-model-repository-scc.yaml
```

or

```yaml
oc create -f sas-model-repository-scc.yaml
```

### Bind the Security Context Constraints to a Service Account

After the security context constraints have been applied, you must link the
security context constraints to the appropriate service account that will use
it. Use the following command:

```yaml
oc -n {{ NAME-OF-NAMESPACE }} adm policy add-scc-to-user sas-model-repository -z
sas-model-repository
```

## Installation

1. Make the following changes to the kustomization.yaml file in the $deploy
   directory:

   - Add sas-bases/overlays/sas-model-repository/service-account/sa.yaml to the
     resources block.
   - Add
     sas-bases/overlays/sas-model-repository/service-account/sa-transformer.yaml
     to the transformers block.

   Here is an example:

   ```yaml
   resources:
     - sas-bases/overlays/sas-model-repository/service-account/sa.yaml

   transformers:
     - sas-bases/overlays/sas-model-repository/service-account/sa-transformer.yaml
   ```

2. Complete the deployment steps to apply the new settings. See
   [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm)
   in _SAS Viya Platform: Deployment Guide_.

   **Note:** This overlay can be applied during the initial deployment of the
   SAS Viya platform or after the deployment of the SAS Viya platform.

   - If you are applying the overlay during the initial deployment of the SAS
     Viya platform, complete all the tasks in the README files that you want to
     use, then run `kustomize build` to create and apply the manifests.
   - If the overlay is applied after the initial deployment of the SAS Viya
     platform, run `kustomize build` to create and apply the manifests.

## Post-Installation Tasks

### Verify the Service Account Configuration

1. Run the following command to verify whether the overlay has been applied:

   ```sh
   kubectl -n <name-of-namespace> get pod <sas-model-repository-pod-name> -oyaml | grep serviceAccount
   ```

2. Verify that the output contains the service-account sas-model-repository.

   ```yaml
   serviceAccount: sas-model-repository
   serviceAccountName: sas-model-repository
   ```
