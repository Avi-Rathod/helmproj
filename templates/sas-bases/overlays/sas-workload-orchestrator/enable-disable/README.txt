---
category: SAS Workload Orchestrator Service
tocprty: 5
---

# Disabling and Enabling SAS Workload Orchestrator Service

## Overview

The SAS Workload Orchestrator Service consists of a set of manager
pods controlled by the sas-workload-orchestrator statefulset and
a set of server pods controlled by the sas-workload-orchestrator
daemonset.

This README file describes how to automatically disable (or enable)
the SAS Workload Orchestrator Service by disabling (or enabling) the
sas-workload-orchestrator statefulset and daemonset.

## Instructions

### Automatically Disable the SAS Workload Orchestrator Service

Because the SAS Workload Orchestrator Service is enabled by default,
there is no action needed to automatically enable the statefulset
and daemonset pods.

You can automatically disable the SAS Workload Orchestrator Service
by adding a patch transformer to the main kustomization.yaml
file so that no statefulset pods and no daemonset pods are created.

To automatically disable the service, add a reference to the disable patch
transformer file into the transformers block of the base kustomization.yaml
file (`$deploy/kustomization.yaml`).

Here is an example:

```yaml
transformers:
...
- sas-bases/overlays/sas-workload-orchestrator/enable-disable/sas-workload-orchestrator-disable-patch-transformer.yaml
```

### Manually Disable or Enable the SAS Workload Orchestrator Service

Manually enable or disable the SAS Workload Orchestrator Service
statefulset and daemonset pods by using the 'kubectl patch'
command along with supplied patch files. There are four files, two for
enabling the daemonset and statefulset, and two for disabling the
daemonset and statefulset.

Since manually disabling or enabling of the SAS Workload Orchestrator Service
is done from a machine that is running kubectl with access to the cluster,
the files from `$deploy/sas-bases/overlays/sas-workload-orchestrator/enable-disable`
must be accessible on that machine either by mounting the overlays directory to the
machine or copying the files to the machine running the kubectl command.

Both disabling and enabling manually require two kubectl patch commands, one for the
sas-workload-orchestrator daemonset and one for the sas-workload-orchestrator statefulset.

#### Disabling

1. Terminate the daemonset pods:

   ```
   kubectl -n <namespace> patch daemonset sas-workload-orchestrator --patch-file /<path>/<to>/sas-workload-orchestrator-patch-daemonset-disable.yaml
   ```

2. Wait for daemonset pods to terminate, and then terminate the statefulset pods:

   ```
   kubectl -n <namespace> patch statefulset sas-workload-orchestrator --patch-file /<path>/<to>/sas-workload-orchestrator-patch-statefulset-disable.yaml
   ```

3. Disable SAS Workload Orchestrator through the SAS Launcher:

   ```
   kubectl -n <namespace> set env deployment sas-launcher -c sas-launcher SAS_LAUNCHER_SWO_DISABLED="true"
   ```

#### Enabling

1. Enable the statefulset pods:

   ```
   kubectl -n <namespace> patch statefulset sas-workload-orchestrator --patch-file /<path>/<to>/sas-workload-orchestrator-patch-statefulset-enable.yaml
   ```

2. Wait for both statefulset pods to become running, and then enable the daemonset pods:

   ```
   kubectl -n <namespace> patch daemonset sas-workload-orchestrator --patch-file /<path>/<to>/sas-workload-orchestrator-patch-daemonset-enable.yaml
   ```

3. Enable SAS Workload Orchestrator through the SAS Launcher:

   ```
   kubectl -n <namespace> set env deployment sas-launcher -c sas-launcher SAS_LAUNCHER_SWO_DISABLED="false"
   ```