---
category: SAS Workload Orchestrator Service
tocprty: 1
---

# Configuration Settings for SAS Workload Orchestrator Service

## Overview

The SAS Workload Orchestrator Service manages the workload which is started on demand by the launcher service.
The SAS Workload Orchestrator Service has manager pods in a StatefulSet and server pods in a DaemonSet.

This README file describes the changes that can be made to the SAS Workload
Orchestrator Service settings for pod resource requirements, for
user-defined resource scripts, for the initial configuration of the
service, and for specifying a different Prometheus Pushgateway URL than the
default.

IMPORTANT: It is strongly recommended that deployments of SAS Workload Orchestrator
also have the ClusterRoleBinding. For details, see the README located at
`$deploy/sas-bases/overlays/sas-workload-orchestrator/README.md` (for Markdown format) or at
`$deploy/sas-bases/docs/cluster_privileges_for_sas_workload_orchestrator_service.htm` (for HTML format).

### Pod Resource Requests and Limits

Kubernetes pods have resource requests and limits for CPU and memory.

Manager pods handle all the REST API calls and manage all of the processing
of host, job, and queue information. The more jobs you process at the same time,
the more memory and cores you should assign to the StatefulSet pods.
For manager pods, the current default resource request and limit for CPU and
memory is 1 core and 4GB of memory.

Server pods interact with Kubernetes to manage the resources and jobs running
on a particular node. Their memory and core requirements depend on how jobs are
allowed to concurrently run on a node and how many pods not started by the
SAS Workload Orchestrator Service are also running on a node.
For server pods, the current default resource request and limit for CPU and
memory is 0.1 core and 250MB of memory.

Generally, manager pods use more resources than daemon pods with the
resource request amount equalling the limit amount.

### Pod User-Defined Script Volume

SAS Workload Orchestrator allows user-defined resources to be used
for scheduling. User-defined resources can be a specified value or can
be a value returned by executing a script.

Manager pods handle the running of user-defined resource scripts for
resources that affect the scheduling on a global scale. An example of
a global resource would be the number of licenses across all pods started
by SAS Workload Orchestrator.

Server pods also handle the running of user-defined resource scripts for
resources that reflect values about an individual node that a pod would run on.
An example of a host resource could be number of GPUs on a host (for the
case of a static resource) or the amount of disk space left on a mount (for
the case of a dynamic resource).

In order to set these values, SAS Workload Orchestrator looks for a script
in a volume mount named "/scripts". To place a script in that directory,
the script must be placed in a volume and that volume specified in the
StatefulSet or DaemonSet definition as a volume with the name 'scripts'.

### SAS Workload Orchestrator Initial Configuration

As of the 2024.09 cadence, the default SAS Workload Orchestrator configuration is
loaded from the sas-workload-orchestrator-initial-configuration ConfigMap.
If the initial configuration needs to be modified, the ConfigMap can be
modified by a patch transformer.

### Custom Prometheus Pushgateway

As of the 2024.09 cadence, the Prometheus Pushgateway used by SAS Workload Orchestrator
can be specified by an environment variable allowing customers to change where
SAS Workload Orchestrator sends its metric information. A patch transformer is provided
to allow a custom URL to be set in the SAS Workload Orchestrator Daemonset configuration.
If the environment variable is not specified, the metrics are sent to
`http://prometheus-pushgateway:9091`.

## Installation

Based on the following descriptions of available example files, determine if you
want to use any example file in your deployment. If so, copy the example
file and place it in your site-config directory.

The example files described in this README file are located at
'/$deploy/sas-bases/examples/sas-workload-orchestrator/configure'.

### StatefulSet Pods Requests and Limits

The values for memory and CPU resources for the SAS Workload Orchestrator Service manager pods
are specified in `sas-workload-orchestrator-statefulset-resources.yaml`.

To update the defaults, replace the `{{ MEM-REQUIRED }}` and `{{ CPU-REQUIRED }}` variables
with the values you want to use.

**Note:** It is important that the values for the requests and limits
be identical to get Guaranteed Quality of Service for the SAS Workload Orchestrator Service pods.

Here is an example:

```yaml
  - op: replace
    path: /spec/template/spec/containers/0/resources/requests/memory
    value: 6Gi
  - op: replace
    path: /spec/template/spec/containers/0/resources/limits/memory
    value: 6Gi
  - op: replace
    path: /spec/template/spec/containers/0/resources/requests/cpu
    value: "2"
  - op: replace
    path: /spec/template/spec/containers/0/resources/limits/cpu
    value: "2"
```

**Note:** For details on the value syntax used in the code, see
[Resource units in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes).

After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

```yaml
transformers:
...
- site-config/sas-workload-orchestrator/configure/sas-workload-orchestrator-statefulset-resources.yaml
```

### DaemonSet Pods Requests and Limits

The values for memory and CPU resources for the SAS Workload Orchestrator Service server pods
are specified in `sas-workload-orchestrator-daemonset-resources.yaml`.

To update the defaults, replace the `{{ MEM-REQUIRED }}` and `{{ CPU-REQUIRED }}` variables
with the values you want to use.

**Note:** It is important that the values for the requests and limits
be identical to get Guaranteed Quality of Service for the SAS Workload Orchestrator Service pods.

Here is an example:

```yaml
  - op: replace
    path: /spec/template/spec/containers/0/resources/requests/memory
    value: 4Gi
  - op: replace
    path: /spec/template/spec/containers/0/resources/limits/memory
    value: 4Gi
  - op: replace
    path: /spec/template/spec/containers/0/resources/requests/cpu
    value: "1500m"
  - op: replace
    path: /spec/template/spec/containers/0/resources/limits/cpu
    value: "1500m"
```

**Note:** For details on the value syntax used in the code, see
[Resource units in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)

After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

```yaml
transformers:
...
- site-config/sas-workload-orchestrator/configure/sas-workload-orchestrator-daemonset-resources.yaml
```

### User-Defined Scripts Volume for Manager Pods

The example file `sas-workload-orchestrator-global-user-defined-resources-script-storage.yaml`
mounts an NFS volume as the 'scripts' volume.

To update the volume, replace the `{{ NFS-SERVER-ADDR }}` variable with the fully-qualified
domain name of the server and replace the `{{ NFS-SERVER-PATH }}` variable with the path to
the volume on the server. Here is an example:

```yaml
  - op: replace
    path: /spec/template/spec/volumes/0
    value:
      name: scripts
      nfs:
        path: /path/to/my/scripts
        server: my.nfs.server.mydomain.com
```

Alternately, you could use any other type of volume Kubernetes supports.

The following example updates the volume to use a PersistentVolumeClaim
instead of an NFS mount. This assumes the PVC has already been defined and created.

```yaml
  - op: replace
    path: /spec/template/spec/volumes/0
    value:
      name: scripts
      persistentVolumeClaim:
        claimName: my-pvc-name
        readOnly: true
```

**Note:** For details on the value syntax used specifying volumes, see
[Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/).

After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

```yaml
transformers:
...
- site-config/sas-workload-orchestrator/configure/sas-workload-orchestrator-global-user-defined-resources-script-storage.yaml
```

### DaemonSet Pods User-Defined Script Volume

The example file `sas-workload-orchestrator-host-user-defined-resources-script-storage.yaml`
mounts an NFS volume as the 'scripts' volume.

To update the volume, replace the `{{ NFS-SERVER-ADDR }}` variable with the fully-qualified
domain name of the server and replace the `{{ NFS-SERVER-PATH }}` variable with the path to
the volume on the server. Here is an example:

```yaml
  - op: replace
    path: /spec/template/spec/volumes/0
    value:
      name: scripts
      nfs:
        path: /path/to/my/scripts
        server: my.nfs.server.mydomain.com
```

Alternately, you could use any other type of volume Kubernetes supports.

The following example updates the volume to use a PersistentVolumeClaim
instead of an NFS mount. This assumes the PVC has already been defined and created.

```yaml
  - op: replace
    path: /spec/template/spec/volumes/0
    value:
      name: scripts
      persistentVolumeClaim:
        claimName: my-pvc-name
        readOnly: true
```

**Note:** For details on the value syntax used specifying volumes, see
[Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/).

After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

```yaml
transformers:
...
- site-config/sas-workload-orchestrator/configure/sas-workload-orchestrator-host-user-defined-resources-script-storage.yaml
```

### Custom Initial SAS Workload Orchestrator Configuration

The example file `sas-workload-orchestrator-initial-configuration-change.yaml`
changes the initial SAS Workload Orchestrator configuration to add
additional administrators.

To update the initial configuration, replace the `{{ NEW_CONFIG_JSON }}` variable with the
JSON representation of the updated configuration. Here is an example:

```yaml
  - op: replace
    path: /data/SGMG_CONFIG_JSON
    value: |
        {
          "version" : 1,
          "admins"  : ["SASAdministrators","myAdmin1","myAdmin2"],

          "hostTypes":
          [
              {
                "name"           : "default",
                "description"    : "SAS Workload Orchestrator Server Hosts on Kubernetes Nodes",
                "role"           : "server"
              }
          ]
        }
```

After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

```yaml
transformers:
...
- site-config/sas-workload-orchestrator/configure/sas-workload-orchestrator-initial-configuration.yaml
```

**Note:** The SAS Workload Orchestrator configuration in JSON can be exported by the Workload Orchestrator
dialog in SAS Environment Manager application or it can be retrieved by using the workload-orchestrator
plugin to the sas-viya CLI.

### Changing Prometheus Pushgateway URL

The example file `sas-workload-orchestrator-prometheus-gateway-url.yaml` changes the
Prometheus Pushgateway URL from the default of `http://prometheus-pushgateway:9091`
to the value specified by the `SGMG_PROMETHEUS_PUSHGATEWAY_URL` environment variable.

To update the URL, replace the `{{ PROMETHEUS_PUSHGATEWAY_URL }}` variable with the
URL where SAS Workload Orchestrator should push its metrics. Here is an example:

```yaml
  - op: add
    path: /spec/template/spec/containers/0/env/-
    value:
        name: SGMG_PROMETHEUS_PUSHGATEWAY_URL
        value: https://my-prometheus-pushgateway.mycompany.com
```

After you have edited the file, add a reference to it to the transformers
block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

```yaml
transformers:
...
- site-config/sas-workload-orchestrator/configure/sas-workload-orchestrator-prometheus-pushgateway-url.yaml
```