---
category: SAS Micro Analytic Service
tocprty: 3
---

# Configure SAS Micro Analytic Service to Support Archive for Log Step Execution

## Overview

If enabled, the SAS Micro Analytic Service archive feature records the inputs and outputs of step execution to a set of rolling log files. 
To use the archive feature, SAS Micro Analytic Service must be configured with a persistent volume to use as a location in which to store the log files. 
This README describes how to configure SAS Micro Analytic Service to use a PersistentVolumeClaim to define storage for the archive logs. 

By default, the archive feature is not enabled. This README also provides a link to where you can find more information about how to enable the archive feature in SAS Micro Analytic Service.

## Prerequisites

The archive feature requires storage with ReadWriteMany access mode for storing transaction logs. A peristentVolumeClaim is defined to specify the storage required.

**Note:** The STORAGE-CLASS-NAME from the cloud provider is used to determine the STORAGE-CAPACITY that is required for your archives. The required storage capacity depends on the expected transaction volume, the size of your payloads, and your backup strategy.

## Installation

1. Copy the files in `$deploy/sas-bases/examples/sas-microanalytic-score/archive` to the `$deploy/site-config/sas-microanalytic-score/archive` directory. Create the destination directory if it does not exist.

   **Note:** If the destination directory already exists, [verify that the overlay](#verify-overlay-for-the-persistent-volume) has been applied. 
   If the output contains the `/opt/sas/viya/config/var/log/microanalyticservice/default/archive` mount directory path, you do not need to take any further actions, unless you want to change the overlay parameters for the mounted directory.

2. The resources.yaml file in `$deploy/site-config/sas-microanalytic-score/archive` contains the parameters of the storage that is required in the PeristentVolumeClaim. For more information about PersistentVolumeClaims, see [Additional Resources](#additional-resources).

   * Replace {{ STORAGE-CAPACITY }} with the amount of storage required.
   * Replace {{ STORAGE-CLASS-NAME }} with the appropriate storage class from the cloud provider that supports ReadWriteMany access mode.

3. Make the following changes to the kustomization.yaml file in the $deploy directory:

   * Add site-config/sas-microanalytic-score/archive/resources.yaml to the resources block.
   * Add sas-bases/overlays/sas-microanalytic-score/archive/archive-transformer.yaml to the transformers block.
 
   Here is an example:

   ```yaml
   resources:
   - site-config/sas-microanalytic-score/archive/resources.yaml

   transformers:
   - sas-bases/overlays/sas-microanalytic-score/archive/archive-transformer.yaml
   ```

4. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya Platform: Deployment Guide_.

   **Note:** This overlay can be applied during the initial deployment of the SAS Viya platform or after the deployment of the SAS Viya platform.
   
   * If you are applying the overlay during the initial deployment of the SAS Viya platform, complete all the tasks in the README files that you want to use, then run `kustomize build` to create and apply the manifests.
   * If the overlay is applied after the initial deployment of the SAS Viya platform, run `kustomize build` to create and apply the manifests.
           
## Post-Installation Tasks

### Verify Overlay for the Persistent Volume

1. Run the following command to verify whether the overlay has been applied:

   ```sh
   kubectl describe pod  <sas-microanalyticscore-pod-name> -n <name-of-namespace>
   ```
   
2. Verify that the output contains the following mount directory path:

   ```yaml
   Mounts:
     /opt/sas/viya/config/var/log/microanalyticservice/default/archive from archives-volume (rw)
   ```

### Enable the Archive Feature in SAS Environment Manager

After the deployment is complete, the SAS Micro Analytic Service archive feature must be enabled in SAS Environment Manager.
For more information, see [Archive Feature Configuration](http://documentation.sas.com/?cdcId=mascdc&cdcVersion=default&docsetId=masag&docsetTarget=n0yfb6f53gngamn1tn7k0a5c60i6.htm) in _SAS Micro Analytic Service: Programming and Administration Guide_.

## Additional Resources

* [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
* [Persistent Volume Claims in Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)