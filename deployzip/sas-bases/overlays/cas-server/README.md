---
category: cas
tocprty: 3
---


# CAS Server for the SAS Viya Platform

## Overview

This directory contains files to Kustomize your SAS Viya platform deployment to use a multi-node
SAS Cloud Analytic Services (CAS) server, referred to as MPP.

## Instructions

### Edit the kustomization.yaml File

In order to add this CAS server to your deployment, add a reference to the `cas-server` overlay
to the resources block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

```yaml
resources:
- sas-bases/overlays/cas-server
```

### Modifying the Number of CAS Workers (MPP Only)

On an MPP CAS Server, the number of workers helps determine the processing power
of your cluster. The server is SMP by default which means there are no workers.
The default number of workers in the cas-server overlay (0) can be modified by
using  the `cas-manage-workers.yaml` example located in the cas examples directory
at `/$deploy/sas-bases/examples/cas/configure`. The number of workers cannot exceed
the number of nodes in your k8s cluster, so ensure that you have enough resources
to accommodate the value you choose.

### Additional Modifications

You can make modifications to the overlay through the use of
Patch Transformers. Examples are located in `/$deploy/sas-bases/examples/cas/configure`,
including how to add additional volume mounts and data connectors, modifying CAS
server resource allocation, and changing the default PVC access modes.

To be included in the manifest, any yaml files containing Patch Transformers must
also be added to the transformers block of the base kustomization.yaml file:

```yaml
transformers:
- {{ PATCH-FILE-1 }}
- {{ PATCH-FILE-2 }}
```

### Optional CAS Server Placement Configuration

If you have an environment where there are untainted nodes, the Kubernetes
scheduler may consider them candidates for the CAS Server. You can use
an additional overlay to restrict the scheduling of the
CAS server to nodes that have the dedicated label.

The dedicated label is `workload.sas.com/class=cas`

The label can be applied to a node with this command:

`kubectl label nodes node1 workload.sas.com/class=cas --overwrite`

To add the label to the CAS Server,
add `sas-bases/overlays/cas-server/require-cas-label.yaml`
to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

Here is an example:

```yaml
...
transformers:
...
- sas-bases/overlays/cas-server/require-cas-label.yaml
...
```

Alternatively, you can use the `sas-bases/overlays/cas-server/require-cas-label-pools.yaml` transformer if your deployment meets all of the following conditions:

* You are using two node pools for your CAS Server deployment.
* You have one node pool labeled and tainted `workload.sas.com/class=cascontroller` to be used exclusively by the controller.
* You have a separate node pool labeled and tainted `workload.sas.com/class=casworker`.

If your deployment meets these conditions, add `sas-bases/overlays/cas-server/require-cas-label-pools.yaml` to the transformers block of the base kustomization.yaml file. Here is an example:

```yaml
...
transformers:
...
- sas-bases/overlays/cas-server/require-cas-label-pools.yaml
...
```

### CAS Configuration on an OpenShift Cluster

The `/$deploy/sas-bases/examples/cas/configure` directory contains a file to
grant Security Context Constraints for fsgroup 1001 on an OpenShift cluster. A
Kubernetes cluster administrator should add these Security Context Constraints
to their OpenShift cluster prior to deploying the SAS Viya platform. Use one of the
following commands:

Step 1:

```yaml
kubectl apply -f cas-server-scc.yaml
```

or

```yaml
oc create -f cas-server-scc.yaml
```

Step 2:

After the SCC has been applied, you must link the SCC to the appropriate ServiceAccount that will use it.
Perform the following command which corresponds to the appropriate host launch type:

No host launch:
oc -n {{ NAME-OF-NAMESPACE }} adm policy add-scc-to-user sas-cas-server -z sas-cas-server

Host launch enabled:
oc -n {{ NAME-OF-NAMESPACE }} adm policy add-scc-to-user sas-cas-server-host -z sas-cas-server

Note: If you are enabling host launch, use the SecurityContexConstraint file
cas-server-scc-host-launch.yaml instead of cas-server-scc.yaml. This file sets
the correct capabilities and privilege escalation

### CAS Auto-Restart During Version Updates

By default, CAS does not automatically restart during version updates performed
by the SAS Viya Platform Deployment Operator. The default prevents the disruption of active
CAS sessions so that tables do not need to be reloaded. This default behavior can be changed by
applying the `cas-auto-restart.yaml` example file located at `/$deploy/sas-bases/examples/cas/configure`.
The example applies the autoRestart option to the pod spec.
The deployment operator checks for this option on all existing CAS servers during
software updates, and it automatically restarts servers that are tagged in this way.

1. Copy the `/$deploy/sas-bases/examples/cas/configure/cas-auto-restart.yaml`
to the site-config directory.

2. By default, the target for this patch applies to all CAS servers:

   ```yaml
   target:
     group: viya.sas.com
     kind: CASDeployment
     name: .*
     version: v1alpha1
   ```

   To target specific CAS servers, list the CAS servers to which the change should
   be applied in the name field.

   ```yaml
   target:
     group: viya.sas.com
     kind: CASDeployment
     name: {{ NAME-OF-SERVER }}
     version: v1alpha1
   ```

3. Add the `cas-auto-restart.yaml` file to the transformers section of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example that
assumes the file was copied to the `$deploy/site-config/cas/configure` directory:

   ```yaml
   transformers:
   ...
   - site-config/cas/configure/cas-auto-restart.yaml
   ...
   ```

4. In order to validate that the auto-restart option has been enabled on for a CAS server, this command may be run:

   ```bash
   kubectl -n <name-of-namespace> get pods <cas-server-pod-name> --show-labels
   ```

   If the label `sas.com/cas-auto-restart=true` is visible, then the auto-restart option has been applied successfully.

5. If you subsequently want to disable auto-restart then remove `cas-auto-restart.yaml` from your transformers list to disable auto-restart for any future CAS servers.  If you want to disable auto-restart on a CAS server that is already running, run the following command to disable auto-restart for that active server:

   ```bash
   kubectl -n <name-of-namespace> label pods --selector=app.kubernetes.io/instance=<cas-deployment-name> sas.com/cas-auto-restart=false
   ```

**Note:** You cannot enable both CAS auto-restart and state transfer in the same SAS Viya platform deployment.

**Note:** Ideally this option should be set as a pre-deployment task. However, it can be applied to an already running CAS server, but that server must be manually restarted in order for the auto-restart option to be turned on.

## Build

After you configure Kustomize, continue your SAS Viya platform deployment as documented.

## Additional Resources

For more information about the difference between SMP and MPP CAS, see [What is the CAS Server, SMP, and MPP?](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=itopscon&docsetTarget=n0tx1x9gu37i7qn1nuv8inwzrfet.htm&locale=en#n0dj3c2j49krjhn1jho4z6daw5n1).
