---
category: sasProgrammingEnvironment
tocprty: 20
---

# SAS GPU Reservation Service for SAS Programming Environment

## Overview

The SAS GPU Reservation Service aids SAS processes in resource sharing and
utilization of the Graphic Processing Units (GPUs) that are available in a
Kubernetes pod. The SAS Programming Environment container image makes this
service available, but it must be enabled in order to take advantage of the GPUs in
your cluster.

***Note:*** The following servers create Kubernetes pods using the SAS Programming Environment container image:

* SAS Compute server
* SAS/CONNECT server
* SAS Batch server

The SAS GPU Reservation Service is supported on all of the supported cloud platforms.
In a Microsoft Azure Kubernetes deployment, additional configuration steps are required.

## Azure Configuration

If you are deploying the SAS Viya platform on Microsoft Azure, before you enable the SAS Programming
Environment to use GPUs, you must configure the Azure Kubernetes Service (AKS) cluster.
The `compute` node pool must be configured with a properly sized N-Series Virtual Machine (VM). The N-Series VMs in Azure have GPU capabilities.

### Using Azure CLI or Azure Portal

If the `compute` node pool already exists, the VM node size cannot be changed.  The `compute` node
pool must be deleted and then recreated to the proper VM size and node count with the following commands.

**WARNING**: Deleting a node pool on an actively running SAS Viya platform deployment will cause any active sessions
to be prematurely terminated.  These steps should only be performed on an idle deployment.
The node pool can be deleted and recreated using the Azure portal or the Azure CLI.

```bash
az aks nodepool delete --cluster-name <replace-with-aks-cluster-name> --name compute --resource-group <replace-with-resource-group>

az aks nodepool add --cluster-name <replace-with-aks-cluster-name> --name compute --resource-group <replace-with-resource-group> --node-count <replace with node count> --node-vm-size "<replace with N-Series VM>" [--zones <replace-with-availability-zone-number>]
```

### Using SAS Viya Infrastructure as Code for Microsoft Azure

SAS Viya 4 Infrastructure as Code (IaC) for Microsoft Azure [(viya4-iac-azure)](https://github.com/sassoftware/viya4-iac-azure) contains Terraform scripts to provision Microsoft Azure Cloud infrastructure
resources required to deploy SAS Viya platform products.  Edit the terraform.tfvars file and change the
`machine_type` for the `compute` node pool to an N-Series VM.

```yaml
node_pools = {
  compute = {
    "machine_type" = "<Change to N-Series VM>"
  ...
  }
},
...
```

Then verify the `compute` node pool was created and properly sized.

```bash
az aks nodepool list -g <resource-group> --cluster-name <cluster-name> --query '[].{Name:name, vmSize:vmSize}'
```

### Using the NVIDIA Device Plug-In

An additional requirement in a Microsoft Azure environment is that the
[NVIDIA device plug-in](https://docs.microsoft.com/en-us/azure/aks/gpu-cluster) must be
installed and configured. Download the example nvidia-device-plugin-ds.yaml manifest
from that Microsoft page. Then add the following to the `tolerations` block of the
manifest so that the plug-in will be scheduled on to the `compute` node pool.

```yaml
tolerations:
...
- key: workload.sas.com/class
  operator: Equal
  value: "compute"
  effect: NoSchedule
...
```

Create the `gpu-resources` namespace and apply the updated manifest to create the NVIDIA device plug-in DaemonSet.

```bash
kubectl create namespace gpu-resources
kubectl apply -f nvidia-device-plugin-ds.yaml
```

## Enable the SAS GPU Reservation Service for SAS Programming Environment

SAS has provided an overlay to enable the SAS GPU Reservation Service for SAS Programming Environment in your environment.

To use the overlay:

1. Add a reference to the `sas-programming-environment/gpu` overlay to the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/sas-programming-environment/gpu
   - sas-bases/overlays/required/transformers.yaml
   ...
   ```

   **NOTE:** The reference to the `sas-programming-environment/gpu` overlay **MUST** come before the required transformers.yaml, as seen in the example above.

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm).

### Disabling the SAS GPU Reservation Service for SAS Programming Environment

To disable the SAS GPU Reservation Service.

1. Remove `sas-bases/overlays/sas-programming-environment/gpu`
from the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

2. Deploy the software using the commands in
[SAS Viya Platform: Deployment Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm).