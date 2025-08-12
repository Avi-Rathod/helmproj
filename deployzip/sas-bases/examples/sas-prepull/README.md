---
category: SAS Image Staging
tocprty: 1
---

# SAS Image Staging Configuration Options

## Overview

SAS Image Staging ensures images are pulled to and staged properly on respective nodes
in an effort to decrease start-up times of various SAS Viya platform components. This README
describes how to customize your SAS Viya platform deployment for tasks related to SAS Image
Staging.

SAS provides the ability to modify the behavior of the SAS Image Staging application
to fit the needs of specific environments.

This README describes two areas that can be configured, the mode of operation and the check
interval.

## SAS Image Staging Requirements

SAS Image Staging requires that Workload Node Placement (WNP) be used. Specifically, at
least one node in the Kubernetes cluster be labeled "workload.sas.com/class=compute" in
order for SAS Image Staging to function properly.

If WNP is not used, the SAS Image Staging application will not pre-stage images.
Timeouts can occur when images are pulled into the cluster the first time or when the
image is removed from the image cache and the image needs to be
pulled again for use.

For more information about WNP, see [Plan the Workload Placement](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p0om33z572ycnan1c1ecfwqntf24.htm).

## Modes of Operation

The default behavior of SAS Image Staging is to start pods on nodes via a daemonset
at interval to ensure that relevant images have been pulled to hosts. While this
default behavior accomplishes the goal of pulling images to nodes and decreasing
start-up times, some users may want more intelligent and specific control with less
churn in Kubernetes.

In order for the non-default option described in this README to function, the SAS
Image Staging application must have the ability to list nodes. The nodes resource is
cluster-scoped and resides outside of the SAS Viya platform namespace. Requirements may not
allow for this sort of access, and default namespace-scoped resources do not provide
the view needed for this option to work.

The SAS Image Staging application uses the list of nodes to determine which images are
currently pulled to the node and their respective version. If an image is
missing or a different version exists on the node, the SAS Image Staging application
will target that node for a pull of the image instead of starting daemonsets
to pull images.

Regardless of the mode of operation, it is normal to see a number of pods that contain
the word "prepull" in their name. The name and frequency in which these pods show up
depend on the mode of operation used. These pods are transient and are used to pull
images to respective nodes.

### Advantages and Disadvantages of the Two Options

#### Daemonset (Default Behavior)

Advantages:

* No need for ClusteRole and ClusterRoleBindings that allow access to cluster-scoped
resources and verbs (nodes and list respectively).
* No modifications via the example described in this README.

Disadvantages:

* Slower to pull, especially when nodes are added since there is no way to target
specific nodes via the namespace scope. At most, a pull requires two minutes plus the
time it takes to pull the image to a node.
* Produces more churn in Kubernetes because daemonsets are firing up to make
sure images are pulled to labeled nodes.
* Produces more log output in SAS Image Staging pod.

#### Node List (Optional Behavior)

Advantages:

* Quicker to pull. A pull requires 30 seconds plus the time it takes to pull the image
to a node.
* Less churn since specific nodes are targeted for pulls.
* Less log output in SAS Image Staging Pod.

Disadvantages:

* Applying the example file described in this README is an extra step from the default.
* This options requires that the sas-prepull service account, a namespaced account,
has cluster-scoped access to resource node and verb list.

## Installation

### Enable the Node List Option

`$deploy/sas-bases/examples/sas-prepull` contains an example file named add-prepull-cr-crb.yaml.
This example provides a resource to permit access to resource node and verb list for
the namespaced sas-prepull service account.

To enable the Node List Option:

1. Copy `$deploy/sas-bases/examples/sas-prepull/add-prepull-cr-crb.yaml` to
`$deploy/site-config/sas-prepull/add-prepull-cr-crb.yaml`.

2. Modify add-prepull-cr-crb.yaml by replacing all instances of '{{ NAMESPACE }}' with the
namespace of the SAS Viya platform deployment where you want node and list access granted for the
sas-prepull service account.

3. Add site-config/sas-prepull/add-prepull-cr-crb.yaml to the resourcess block of the
base kustomization.yaml file (`$deploy/kustomization.yaml`).

   Here is an example:

   ```yaml
   ...
   resources:
   ...
   - site-config/sas-prepull/add-prepull-cr-crb.yaml
   ...
   ```

4. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

### Modify the Resource Limits

You should increase the resource limit of the SAS Image Staging deployment if the node list option is used and you plan to use autoscaling in your cluster. The default values for CPU and Memory limits are 1 and 1Gi respectively.

The `$deploy/sas-bases/examples/sas-prepull` directory contains an example file named change-resource-limits.yaml.

This example provides a patch that will change the values for resources limits in the SAS Image
Staging application pod.

Steps to modify:

1. Copy `$deploy/sas-bases/examples/sas-prepull/change-resource-limits.yaml` to
`$deploy/site-config/sas-prepull/change-resource-limits.yaml`.

2. Modify change-resource-limits.yaml by replacing the resource limit values to match your
needs.

3. Add site-config/sas-prepull/change-resource-limits.yaml to the transformers block of the
base kustomization.yaml file (`$deploy/kustomization.yaml`).

   Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - site-config/sas-prepull/change-resource-limits.yaml
   ...
   ```

### Disable the Node List Option

1. Remove site-config/sas-prepull/add-prepull-cr-crb.yaml from the resources block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). This is to ensure the option does not
get applied in future Kustomize builds.

2. If there are no other SAS Viya platform deployments in other namespaces in the cluster, execute
`kubectl delete -f $deploy/site-config/sas-prepull/add-prepull-cr-crb.yaml` to remove the
ClusterRole and ClusterRoleBinding from the cluster. If there are other SAS Viya platform deployments
in other namespaces in the cluster, execute `kubectl delete clusterrolebinding sas-prepull-v2-{{ NAMESPACE }} -n {{ NAMESPACE }}`,
where {{ NAMESPACE }} is the namespace of the deployment in which you want the ClusterRoleBinding
removed.

### Modify the Check Interval

The check interval is the time the SAS Image Staging application pauses between checks for newer
versions of images. By default, the check interval in Daemonset mode is 1 hour and the check
interval for Node List mode is 30 secs. These defaults are reasonable given their operation and
impact to an environment. However, you may wish to adjust the interval to further reduce churn
in the environment. This section of the README describes how to make those interval adjustments.

The interval is configured via two options located in the sas-prepull-parameters configmap. Those
options are called SAS_PREPULL_DAEMON_INT and SAS_PREPULL_CRCRB_INT and control the intervals of
Daemon Mode and Node List Mode respectively.

The `$deploy/sas-bases/examples/sas-prepull` directory contains an example file named change-check-interval.yaml.
This example provides a patch that will change the values for the intervals in the configmap
referenced by the SAS Image Staging application.

Steps to modify:

1. Copy `$deploy/sas-bases/examples/sas-prepull/change-check-interval.yaml` to
`$deploy/site-config/sas-prepull/change-check-interval.yaml`.

2. Modify change-check-interval.yaml by replacing all instances of '{{ DOUBLE-QUOTED-VALUE-IN-SECONDS }}'
with the value in seconds for each respective mode. Note that the value must be wrapped in double quotes
in order for Kustomize to appropriately reference the value.

3. Add site-config/sas-prepull/change-check-interval.yaml to the transformers block of the
base kustomization.yaml file (`$deploy/kustomization.yaml`).

   Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - site-config/sas-prepull/change-check-interval.yaml
   ...
   ```

### Using Flattened Image Paths with Red Hat OpenShift

If you are deploying on Red Hat OpenShift and are using a mirror registry, SAS Image Staging requires a modification to work properly. The change-relpath.yaml file in the $deploy/sas-bases/overlays/sas-prepull directory contains a patch for the relative path of images that are pre-staged by SAS Image Staging.

To use the patch, add `sas-bases/overlays/sas-prepull/change-relpath.yaml` to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Make sure the addition is above the line `sas-bases/overlays/required/transformers.yaml`.

Here is an example:

```yaml
...
transformers:
...
- sas-bases/overlays/sas-prepull/change-relpath.yaml
- sas-bases/overlays/required/transformers.yaml
...
```