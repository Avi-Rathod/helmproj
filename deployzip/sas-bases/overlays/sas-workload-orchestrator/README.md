---
category: SAS Workload Orchestrator Service
tocprty: 3
---

# Cluster Privileges for SAS Workload Orchestrator Service

## Overview

SAS Workload Orchestrator Service is an advanced scheduler that integrates with SAS Launcher. SAS recommends adding this overlay to allow
the SAS Workload Orchestrator service account to retrieve the following node and pod information so that your deployment will run optimally.

* Node presence. This tells us whether the node is known by the Kubernetes server. If the node information cannot be accessed, SAS Workload Orchestrator assumes the node is viable from a status point of view even though kubelet might be dead.

* Node allocatable cores and memory. These are used to determine how much memory and how many cores are available to use for scheduling. If the node information cannot be accessed, SAS Workload Orchestrator only knows what the hardware contains, not what is available to Kubernetes to use for pods. Only kubelet knows those amounts.

* Node labels (referred to by SAS Workload Orchestrator as 'host properties'). If the node information cannot be accessed:
  * SAS Workload Orchestrator does not have host properties to use with host types.
    * SAS Workload Orchestrator uses host properties to assign a node to a host type. When host properties are not available, the host type must be selected another way, such as matching host name using regex values.
    * SAS Workload Orchestrator uses the host properties as node labels to set the nodeAffinity for pods that it scales. This setting is required to generate a scaling pod for a specific node pool. If there are no host properties, the scaling pod will only have the label 'workload.sas.com/class=compute' which could match more than one node pool.
  * SAS Workload Orchestrator cannot check to see whether the node has the 'workload.sas.com/class' label set to 'compute' so that it can schedule pods to the node. Instead, SAS Workload Orchestrator assumes it can schedule pods to any node where the SAS Workload Orchestrator DaemonSet pod is running.
* Node 'unschedulable' value. This is used to determine whether a node has been cordoned off so that no pods can be scheduled on it. If the node information cannot be accessed, SAS Workload Orchestrator still schedules pods to a cordoned-off node.
  **Note:** The ability for SAS Workload Manager to recognize that a node has been cordoned is new in release 2024.01.

* Resources used by pods from other namespaces running on the node. This is used to reduce the cores and memory available for scheduling. If the pod information about pods from other namespaces cannot be accessed, the amount of cores and memory available for scheduling is incorrect. This causes OutOfmemory and OutOfcpu launch errors.

If you choose not to allow the ClusterRoleBinding, you must perform the following tasks:

* Prevent pods from other namespaces from running on the compute nodes that are used by the current namespace. This can be done by making both of these changes:
  * Have a node pool that has a special label for each namespace.
  * Change the pod templates for a deployment to require that special node label in the nodeAffinity.

* Group hosts by host name using a regular expression instead of host properties. The cloud vendor might generate node host names based in part on the node pool name.

* Close hosts in SAS Workload Orchestrator instead of using Kubernetes cordoning action.

* Limit the number of pods, jobs, or both that can be started on a node so that the total-pod-resource requirements fit within the nodes' available memory and cores.

* Prepare for kubelet to stop responding when it has a problem.

Without the ability to get node labels as host properties, SAS Workload Orchestrator cannot allocate a new node from the correct node pool when a pod triggers a scale-up. As stated above, SAS Workload Orchestrator uses the host properties (that is, node labels) of the host type to be scaled to create the scaling pod's nodeAffinity information. Without the host properties, the only label in the nodeAffinity section will be 'workload.sas.com/class=compute'. If you have only one deployment in a cluster and only one scalable node pool for the deployment, this is not a problem. If you have multiple deployments and each deployment has a scalable host type or multiple scalable host types, this is a problem because the node information cannot be accessed.

## Instructions

### Enable the ClusterRole

The ClusterRole and ClusterRoleBinding are enabled by adding the file to the resources block of the base kustomization.yaml file
(`$deploy/kustomization.yaml`). Here is an example:

```yaml
resources:
...
- sas-bases/overlays/sas-workload-orchestrator
```

### Disable the ClusterRole

To disable the ClusterRole and ClusterRoleBinding:

1. Remove `sas-bases/overlays/sas-workload-orchestrator` from the resources block of the
base kustomization.yaml file (`$deploy/kustomization.yaml`). This also ensures that the
ClusterRole option will not be applied in future Kustomize builds.

2. Perform the following command to remove the ClusterRoleBinding from the namespace:

   ```bash
   kubectl delete clusterrolebinding sas-workload-orchestrator-<your namespace>
   ```

3. Perform the following command to remove the ClusterRole from the cluster.

   ```bash
   kubectl delete clusterrole sas-workload-orchestrator
   ```

## Build

After you configure Kustomize, continue your SAS Viya platform deployment as documented.