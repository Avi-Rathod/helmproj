---
category: sasProgrammingEnvironment
tocprty: 8
---

# Configuring SAS Compute Server to Use SAS Watchdog

## Overview

The SAS Compute server provides the ability to execute SAS Watchdog, which
monitors spawned processes to ensure that they comply with the terms of LOCKDOWN system option.

The LOCKDOWN system option employs an allow list in the SAS Compute server.  Only files
that reside in paths or folders that are included in the allow list can be accessed by the SAS
Compute server.  The limitation on the LOCKDOWN system option is that it can only block access
to files and folders directly accessed by SAS Compute server processing.  The SAS Watchdog facility
extends this checking to files and folders that are used by languages that are invoked by
the SAS Compute server.   Therefore, code written in Python, R, or Java that is executed directly
in the SAS Compute server process is checked against the allow list. 
The configuration of the SAS Watchdog facility replicates the allow list that
is configured by the LOCKDOWN system option by default.  

**Note:** For more information about the LOCKDOWN system option, see [LOCKDOWN System Option](https://go.documentation.sas.com/doc/en/sasadmincdc/default/calsrvpgm/p04d9diqt9cjqnn1auxc3yl1ifef.htm#p0sshm6ekdjiafn1jm5o0as6dsdr)

The SAS Watchdog facility is disabled by default.  This README file describes how to
customize your SAS Viya platform deployment to allow SAS Compute server to run SAS Watchdog.

## Installation

Enable the ability for the pod where the SAS Compute
Server is running to run SAS Watchdog. SAS Watchdog starts when the SAS
Compute server is started, and exists for the life of
the SAS Compute server.

### Enable SAS Watchdog in the SAS Compute Server

SAS has provided an overlay to enable SAS Watchdog in your environment.

To use the overlay:

1. Add a reference to the `sas-programming-environment/watchdog` overlay to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/sas-programming-environment/watchdog
   - sas-bases/overlays/required/transformers.yaml
   ...
   ```

   **NOTE:** The reference to the `sas-programming-environment/watchdog` overlay **MUST** come before the required transformers.yaml, as seen in the example above.

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

### Disabling SAS Watchdog in the SAS Compute Server

To disable SAS Watchdog:

1. Remove `sas-bases/overlays/sas-programming-environment/watchdog`
from the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

## Additional Instructions for an OpenShift Environment

### Apply Security Context Constraint (SCC)

As a Kubernetes cluster administrator of the OpenShift cluster, use one of the following commands to apply the Security Context Constraint. An example of the yaml may be found in `sas-bases/examples/sas-programming-environment/watchdog/sas-watchdog-scc.yaml`.

```console
kubectl apply -f sas-watchdog-scc.yaml
```

```console
oc apply -f sas-watchdog-scc.yaml
```

### Grant the Service Account Use of the SCC

```console
oc -n <namespace> adm policy add-scc-to-user sas-watchdog -z sas-programming-environment
```

### Remove the Service Account from the SCC

Run the following command to remove the service account from the SCC:

```console
oc -n <namespace> adm policy remove-scc-from-user sas-watchdog -z sas-programming-environment
```

### Delete the SCC

Run one of the following commands to delete the SCC after it has been removed:

```console
kubectl delete scc sas-watchdog
```

```console
oc delete scc sas-watchdog
```

**NOTE:** Do not delete the SCC if there are other SAS Viya platform deployments in the cluster.  Only delete the SCC after all namespaces running SAS Viya platform in the cluster have been removed.