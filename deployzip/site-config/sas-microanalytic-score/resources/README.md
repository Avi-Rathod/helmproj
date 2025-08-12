---
category: SAS Micro Analytic Service
tocprty: 2
---

# Configure CPU and Memory Resources for SAS Micro Analytic Service

## Overview

By default, SAS Micro Analytic Service is deployed with 750 MB of memory and 250m CPU.

If your SAS Micro Analytic Service deployment requires different resources, you can use the resources-transformer.yaml file in the `$deploy/sas-bases/examples/sas-microanalytic-score/resources` directory to configure different values.

## Prerequisites

Determine the minimum and maximum value of memory and CPU required for your deployment. The values depend on available resources in the cluster and your desired throughput.

## Installation

1. Copy the files in `$deploy/sas-bases/examples/sas-microanalytic-score/resources` to the `$deploy/site-config/sas-microanalytic-score/resources` directory. Create destination directory if it does not exist.

   **Note:** If the destination directory already exists, [verify that the overlay](#verify-overlay-for-the-resources) has been applied. 
   You do not need to take any further actions, unless you want to change the CPU and memory parameters to different values.

2. Modify the resources-transformer.yaml in `$deploy/site-config/sas-microanalytic-score/resources` to specify your resource settings. For more information about Kubernetes resources, see [Additional Resources](#additional-resources).

   * Replace {{ MEMORY-REQUIRED }} with the minimum amount of memory required for SAS Micro Analytic Service.
   * Replace {{ MEMORY-LIMIT }} with the maximum amount of memory that can be claimed for SAS Micro Analytic Service.
   * Replace {{ CPU-REQUIRED }} with the minimum number of cores required for SAS Micro Analytic Service.
   * Replace {{ CPU-LIMIT }} with the maximum number of cores that can be claimed for SAS Micro Analytic Service.
 
   **Note:** Kubernetes uses units of measurement that are different from the standard. For memory, use Gi for gigabytes and Ti for terabytes. For cores, Kubernetes uses millicores as its standard, and there are 1000 millicores to a core. Therefore, if you want to use 4 cores, use 4000m as your value. 500m is equivalent to half a core.

3. In the base kustomization.yaml in $deploy directory, add site-config/sas-microanalytic-score/resources/resources-transformer.yaml to the transformers block.

   Here is an example:

   ```yaml
   transformers:
   - site-config/sas-microanalytic-score/resources/resources-transformer.yaml
   ```

4. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya Platform: Deployment Guide_.

   **Note:** This overlay can be applied during the initial deployment of the SAS Viya platform or after the deployment of the SAS Viya platform.
   
   * If you are applying the overlay during the initial deployment of the SAS Viya platform, complete all the tasks in the README files that you want to use, then run `kustomize build` to create and apply the manifests. 
   * If the overlay is applied after the initial deployment of the SAS Viya platform, run `kustomize build` to create and apply the manifests.  
           
## Verify Overlay for the Resources

1. Run the following command to verify whether the overlay has been applied:

   ```sh
   kubectl describe pod  <sas-microanalyticscore-pod-name> -n <name-of-namespace>
   ```
   
2. Verify that the output contains the desired CPU and memory values that you configured:
    
   ```yaml
   Limits:
     cpu:     4
     memory:  2Gi
   Requests:
     cpu:      250m
     memory:   750M
   ```

## Additional Resources

* [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
* [Configuring SAS Micro Analytic Service Resources](http://documentation.sas.com/?cdcId=mascdc&cdcVersion=default&docsetId=masag&docsetTarget=n0xhk2rkiy2ku1n163otwgddvxra.htm) in _SAS Micro Analytic Service: Programming and Administration Guide_
* [Resource Requests and Limits for Pods in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits)