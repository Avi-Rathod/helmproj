---
category: OpenSearch
tocprty: 20
---

# Configure an Internal OpenSearch Instance for the SAS Viya Platform

**Note:** SAS terminology standards prohibit the use of the term "master." However, this document refers to the term "master node" to maintain alignment with OpenSearch documentation.

**Note:** In previous releases, the SAS Viya platform included OpenDistro for Elasticsearch. Many Kubernetes resources keep the name OpenDistro for backwards compatiblity. 


This README file describes the files used to customize an internally managed instance of OpenSearch using the sas-opendistro operator provided by SAS. 

## Instructions

In order to use the internal search cluster instance, you must customize your
deployment to point to the required overlay and transformers.

1. Go to the base kustomization.yaml file (`$deploy/kustomization.yaml`). In the
   resources block of that file, add the following content, including adding
   the block if it does not already exist.

   ```yaml
   resources:
   ...
   - sas-bases/overlays/internal-elasticsearch
   ...
   ```

2. Go to the base kustomization.yaml file (`$deploy/kustomization.yaml`). In the
   transformers block of that file, add the following content, including adding
   the block if it does not already exist.

   ```yaml
   transformers:
   ...
   - sas-bases/overlays/internal-elasticsearch/internal-elasticsearch-transformer.yaml
   ...
   ```

3. Deploying OpenSearch requires configuration to support the ability to create many memory mapped areas if `vm.max_map_count` is set too low. 

   Several methods are available to configure the sysctl option `vm.max_map_count` documented below. Choose a method which is supported for your platform.

   | Method | Platforms | Requirements |
   | ------ | --------- | ------------ |
   | Use sas-opendistro-sysctl init container *(recommended)* | Microsoft Azure Kubernetes Service (AKS) without Microsoft Defender<br/>Amazon Elastic Kubernetes Service (EKS) <br/>Google Kubernetes Engine (GKE)<br/>RedHat Openshift<br/> | Privileged Containers<br/>Allow Privilege Escalation<br/> |
   | Use sas-opendistro-sysctl DaemonSet | Microsoft Azure Kubernetes Service (AKS) with Microsoft Defender | Privileged Containers<br/>Allow Privilege Escalation<br/>Kubernetes nodes for stateful workloads labeled with `workload.sas.com/class` as `stateful` |
   | Apply sysctl configuration manually | All platforms | Ability to configure sysctl on stateful Kubernetes nodes |
   | Disable mmap support | All platforms | Unable to apply sysctl configuration manually or use privileged containers |

* **Use sas-opendistro-sysctl init container**: If your deployment allows privileged containers, add a reference to `sas-bases/overlays/internal-elasticsearch/sysctl-transformer.yaml` to the transformers block of the base kustomization.yaml. The `sysctl-transformer.yaml` transformer must be included before the `sas-bases/overlays/required/transformers.yaml` transformer. Here is an example:

   ```yaml
   transformers:
   - sas-bases/overlays/internal-elasticsearch/sysctl-transformer.yaml
   - sas-bases/overlays/required/transformers.yaml
   ```

* **Use sas-opendistro-sysctl DaemonSet** (Microsoft Azure Kubernetes Service with Microsoft Defender only): If your deployment allows privileged containers and you are deploying to an environment secured by Microsoft Defender, add a reference to `sas-bases/overlays/internal-elasticsearch/sysctl-daemonset.yaml` to the resources block of the base kustomization file. Here is an example:

   ```yaml
   resources:
   - sas-bases/overlays/internal-elasticsearch/sysctl-daemonset.yaml
   ```

* **Apply sysctl configuration manually**: If your deployment does not allow privileged containers, the Kubernetes administrator should set the `vm.max_map_count` property to be at least 262144 for stateful workload nodes.

* **Disable mmap support**: If your deployment does not allow privileged containers and you are in an environment where you cannot control the memory map settings, add a reference to `sas-bases/overlays/internal-elasticsearch/disable-mmap-transformer.yaml` to the transformers block of the base kustomization.yaml to disable memory mapping instead. The `disable-mmap-transformer.yaml` transformer must be included before the `sas-bases/overlays/required/transformers.yaml` transformer. Here is an example: 

   ```yaml
   transformers:
   - sas-bases/overlays/internal-elasticsearch/disable-mmap-transformer.yaml
   - sas-bases/overlays/required/transformers.yaml
   ```

   Disabling memory mapping is discouraged since doing so will negatively impact performance and may result in out of memory exceptions. 
   

4. For additional customization options, refer to the following README files:

* Update the storage class used by OpenSearch: `$deploy/sas-bases/examples/configure-elasticsearch/internal/storage/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configure_a_default_storageclass_for_opensearch.htm` (for HTML format).
* Configure a custom topology for OpenSearch: `$deploy/sas-bases/examples/configure-elasticsearch/internal/topology/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configure_a_default_topology_for_opensearch.htm` (for HTML format).
* Configure a custom run user for OpenSearch: `$deploy/sas-bases/examples/configure-elasticsearch/internal/run-user/README.md` (for Markdown format) or `$deploy/sas-bases/docs/configure_a_run_user_for_opensearch.htm` (for HTML format).
* Additional configuration steps for Red Hat OpenShift: `$deploy/sas-bases/examples/configure-elasticsearch/internal/openshift/README.md` (for Markdown format) or `$deploy/sas-bases/docs/opensearch_on_red_hat_openshift.htm` (for HTML format).
* Additional configuration for OpenSearch Security Audit Logs: `$deploy/sas-bases/examples/configure-elasticsearch/internal/security-audit-logs/README.md` (for Markdown format) or `$deploy/sas-bases/docs/opensearch_security_audit_logs.htm` (for HTML format).

5. After you revise the base kustomization.yaml file, continue your SAS Viya platform
   deployment as documented in
   [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

## Supported Topologies

A single cluster is supported with the following topologies:
* One Node Set with both master and data roles.
* Two Node Sets: one with dedicated master role, and other with dedicated data role.
 
## Operator Constraints

The operator does not support the following actions:
* Dynamically changing a running cluster's properties, PersistentVolumeClaims or topology.
* Deleting PersistentVolumeClaims when a cluster is deleted.

# Upgrade the Internal OpenSearch Operator

## Overview

If you are updating your software, you must perform the following steps.
If you are performing a new deployment of your software, these steps can be
safely ignored.

## Instructions

The following steps need to be performed before applying your manifest for the
new version of the SAS Viya platform. Replace the entire variable
`{{.Values.NAME_OF_NAMESPACE }}`, including the braces, with the Kubernetes
namespace used for the SAS Viya platform.

1. As an administrator with namespace permissions, scale down the existing internal
   OpenSearch Operator deployment:

   ```bash
   kubectl scale deployment --replicas=0 sas-opendistro-operator -n {{ .values.NAME_OF_NAMESPACE  }}
   ```

2. As an administrator with namespace permissions, run the following command.
   The command ensures that there are no pods running the internal OpenSearch
   operator.

   ```bash
   kubectl get po -l name=sas-opendistro-operator -n {{ .values.NAME_OF_NAMESPACE  }}
   ```