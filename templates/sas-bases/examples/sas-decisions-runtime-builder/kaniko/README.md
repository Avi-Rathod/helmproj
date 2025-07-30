---
category: Model Publish service
tocprty: 4
---

# Configure Kaniko for SAS Decisions Runtime Builder Service

## Overview

Kaniko is a tool that is used to build container images from a Dockerfile without depending on a Docker daemon. The Kaniko can build a container image in Kubernetes and then push the built image to the container registry for a specific destination.

The Decisions Runtime Builder service then loads a pod template from the sas-decisions-runtime-builder-kaniko-job-config (as defined in updateJobtemplate.yaml) and dynamically constructs a job specification. The job specification helps mount the directories in the Kaniko container.

The Kaniko container is started after a batch job is executed. The Decisions Runtime Builder service checks the job status every 30 seconds. The job times out after 30 minutes, if it has not completed.

## Prerequisites

If you are deploying in a Red Hat OpenShift cluster, use the following command to link the service account to run as the root user.

```yaml
oc -n {{ NAME-OF-NAMESPACE }} adm policy add-scc-to-user anyuid -z sas-decisions-runtime-builder-kaniko
```

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-decisions-runtime-builder/kaniko` directory to the `$deploy/site-config/sas-decisions-runtime-builder/kaniko` directory. Create the destination directory, if it does not already exist.

2. Modify the parameters in the $deploy/site-config/sas-decisions-runtime-builder/kaniko/storage.yaml file. For more information about PersistentVolume Claims (PVCs), see [Persistent Volume Claims on Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims).

   - Replace {{ STORAGE-CAPACITY }} with the amount of storage required.
   - Replace {{ STORAGE-CLASS-NAME }} with the appropriate storage class from the cloud provider that supports ReadWriteMany access mode.

3. Make the following changes to the base kustomization.yaml file in the $deploy directory.

   - Add site-config/sas-decisions-runtime-builder/kaniko to the resources block.
   - Add sas-bases/overlays/sas-decisions-runtime-builder/kaniko/kaniko-transformer.yaml to the transformers block. Here is an example:

   ```yaml
   resources:
     - site-config/sas-decisions-runtime-builder/kaniko

   transformers:
     - sas-bases/overlays/sas-decisions-runtime-builder/kaniko/kaniko-transformer.yaml
   ```

4. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya platform: Deployment Guide_.

> **Note:** This overlay can be applied during the initial deployment of the SAS Viya platform or after the deployment of the SAS Viya platform.

- If you are applying the overlay during the initial deployment of the SAS Viya platform, complete all the tasks in the README files that you want to use, and then run `kustomize build` to create and apply the manifests.
- If the overlay is applied after the initial deployment of the SAS Viya platform, run `kustomize build` to create and apply the manifests.

## Verify the Overlay for Kaniko

Run the following command to verify whether the overlays have been applied. It the overlay is applied, it shows a podTemplate named 'sas-decisions-runtime-builder-kaniko-job-config'.

```sh
kubectl get podTemplates  | grep sas-decisions-runtime-buider-kaniko-job-config
```

## Additional Resources

- [SAS Viya platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
- [Persistent Volume Claims on Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
- [Configuring Publishing Destinations](http://documentation.sas.com/?cdcId=mdlmgrcdc&cdcVersion=default&docsetId=mdlmgrag&docsetTarget=n0x0rvwqs9lvpun16sfdqoff4tsk.htm) in the _SAS Model Manager: Administrator's Guide_
