---
category: Model Publish service
tocprty: 1
---

# Configure Git for SAS Model Publish Service

## Overview

The Model Publish service uses the sas-model-publish-git dedicated
PersistentVolume Claim (PVC) as a workspace. When a user publishes a model to a
Git destination, sas-model-publish creates a local repository under
/models/git/publish/, which is then mounted from the sas-model-publish-git PVC
in the start-up process.

## Files

In order for the Model Publish service to successfully publish a model to a Git
destination, the user must prepare and adjust the following file that are
located in the `$deploy/sas-bases/examples/sas-model-publish/git` directory:

**storage.yaml** - defines a PVC for the Git local repository.

The following file is located in the
`$deploy/sas-bases/overlays/sas-model-publish/git` directory and does not need
to be modified:

**git-transformer.yaml** - adds the sas-model-publish-git PVC to the
sas-model-publish deployment object.

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-model-publish/git`
   directory to the `$deploy/site-config/sas-model-publish/git` directory.
   Create the target directory, if it does not already exist.

   **Note:** If the destination directory already exists,
   [verify that the overlay](#verify-overlay-for-the-persistent-volume) has been
   applied. If the output contains the /models/git/ mount directory path, you do
   not need to take any further actions, unless you want to change the overlay
   parameters for the mounted directory.

2. Modify the parameters in storage-git.yaml. For more information about
   PersistentVolume Claims (PVCs), see
   [Persistent Volume Claims on Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims).

   - Replace {{ STORAGE-CAPACITY }} with the amount of storage required.
   - Replace {{ STORAGE-CLASS-NAME }} with the appropriate storage class from
     the cloud provider that supports ReadWriteMany access mode.

3. Make the following changes to the base kustomization.yaml file in the $deploy
   directory.

   - Add site-config/sas-model-publish/git to the resources block.
   - Add sas-bases/overlays/sas-model-publish/git/git-transformer.yaml to the
     transformers block.

   Here is an example:

   ```yaml
   resources:
     - site-config/sas-model-publish/git

   transformers:
     - sas-bases/overlays/sas-model-publish/git/git-transformer.yaml
   ```

4. Complete the deployment steps to apply the new settings. See
   [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm)
   in _SAS Viya Platform: Deployment Guide_.

   **Note:** This overlay can be applied during the initial deployment of the
   SAS Viya platform or after the deployment of the SAS Viya platform.

   - If you are applying the overlay during the initial deployment of the SAS
     Viya platform, complete all the tasks in the README files that you want to
     use, then run `kustomize build` to create and apply the manifests.
   - If the overlay is applied after the initial deployment of the SAS Viya
     platform, run `kustomize build` to create and apply the manifests.

## Verify Overlay for the Persistent Volume

1. Run the following command to verify whether the overlays have been applied:

   ```sh
   kubectl describe pod  <sas-model-publish-pod-name> -n <name-of-namespace>
   ```

2. Verify that the output contains the following mount directory paths:

   ```yaml
   Mounts: /models/git/publish
   ```

## Additional Resources

- [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
- [Persistent Volume Claims on Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
- [Configuring Publishing Destinations](http://documentation.sas.com/?cdcId=mdlmgrcdc&cdcVersion=default&docsetId=mdlmgrag&docsetTarget=n0x0rvwqs9lvpun16sfdqoff4tsk.htm)
  in the _SAS Model Manager: Administrator's Guide_
