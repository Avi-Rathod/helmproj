---
category: Model Publish service
tocprty: 3
---

# Configure Buildkit for SAS Decisions Runtime Builder Service

## Overview

Buildkit is a tool that is used to build container images from a Dockerfile without depending on a Docker daemon. Buildkit can build a container image in Kubernetes and then push the built image to the container registry for a specific destination.

The Decisions Runtime Builder service uses the sas-decisions-runtime-builder-buildkit dedicated PersistentVolume Claim (PVC) as a cache. It caches builder images and layers beyond the life cycle of single job execution.

The Update request to Decisions Runtime Builder service starts a Kubernetes job to build a new image. The service checks the job status every 30 seconds. The job times out after 30 minutes, if it has not completed.

The Decisions Runtime Builder service deletes the job and the temporary directories after the job has completed successfully, completed with errors, or has timed out.

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-decisions-runtime-builder/buildkit` directory to the `$deploy/site-config/sas-decisions-runtime-builder/buildkit` directory. Create the destination directory, if it does not already exist.

   **Note:** [Verify that the overlay](#verify-overlay-for-the-buildkit) has been applied. If the Buildkit daemon deployment already exists, you do not need to take any further action, unless you want to change the overlay parameters for the mounted directory.

2. Modify the parameters in the files storage.yaml and publish-storage.yaml in the directory $deploy/site-config/sas-decisions-runtime-builder/buildkit. For more information about PersistentVolume Claims (PVCs), see [Persistent Volume Claims on Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims).

   - Replace {{ STORAGE-CAPACITY }} with the amount of storage required.
   - Replace {{ STORAGE-CLASS-NAME }} with the appropriate storage class from the cloud provider that supports ReadWriteMany access mode.

3. Make the following changes to the base kustomization.yaml file in the $deploy directory.

   - Add site-config/sas-decisions-runtime-builder/buildkit to the resources block.
   - Add sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-transformer.yaml to the transformers block.

   Here is an example:

   ```yaml
   resources:
     - site-config/sas-decisions-runtime-builder/buildkit

   transformers:
     - sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-transformer.yaml
   ```

4. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya Platform: Deployment Guide_.

> **Note:** This overlay can be applied during the initial deployment of the SAS Viya platform or after the deployment of the SAS Viya platform.

- If you are applying the overlay during the initial deployment of the SAS Viya platform, complete all the tasks in the README files that you want to use, then run `kustomize build` to create and apply the manifests.
- If the overlay is applied after the initial deployment of the SAS Viya platform, run `kustomize build` to create and apply the manifests.

## Using Buildkit on Clusters with an Incorrect User Namespace Configuration

The sas-buildkitd deployment typically starts without any issues. However, for some cluster deployments, you might receive the following error:

'/proc/sys/user/max_user_namespaces needs to be set to nonzero'

If this occurs, use the buildkit-userns-transformer to configure user namespace support. This is done with an init container that is running in privileged mode during start-up.

1. Add 'sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-certificates-transformer.yaml' to the transformers block after the 'buildkit-transformer.yaml' entry. Here is an example:

   ```yaml
   transformers:
     - sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-transformer.yaml
     - sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-userns-transformer.yaml
   ```

2. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya Platform: Deployment Guide_.

## Using Buildkit with Registries That Use Self-signed Certificates

If the registry contains SAS Viya platform deployment images or the destination registry is using self-signed certificates, those certificates should be added to the buildkit deployment. If they are not, the image build generates a 'certificate signed by unknown authority' error.

If you receive that error, complete the following steps to add self-signed certificates to the Buildkit deployment.

1. Copy the files in the `$deploy/sas-bases/examples/sas-decisions-runtime-builder/buildkit/cert` directory to the `$deploy/site-config/sas-decisions-runtime-builder/buildkit/certs` directory. Create the destination directory, if it does not already exist.

2. Add the self-signed certificates that you want to be trusted to the $deploy/site-config/sas-decisions-runtime-builder/buildkit/certs directory.

   In that directory, edit the kustomization.yaml file to add the certificate files to the files field in the secretGenerator section.

   ```yaml
   resources: []
   secretGenerator:
     - name: sas-buildkit-registry-secrets
       files:
         - registry1.pem
         - regsitry2.pem
   ```

3. Make the following changes to the base kustomization.yaml file in the $deploy directory.

   - Add site-config/sas-decisions-runtime-builder/buildkit/config to the resources block.
   - Add sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-certificates-transformer.yaml to the transformers block after buildkit-transformer.

   Here is an example:

   ```yaml
   resources:
     - site-config/sas-decisions-runtime-builder/buildkit
     - site-config/sas-decisions-runtime-builder/buildkit/certs

   transformers:
     - sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-transformer.yaml
     - sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-certificate-transformer.yaml
   ```

4. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya Platform: Deployment Guide_.

## Verify Overlay for the Buildkit

Run the following command to verify whether the Buildkit overlay has been applied. It should show at least one pod starting with the prefix 'buildkitd'.

```sh
kubectl get pods  |  grep buildkitd
```

## Define the SCR-BUILDER-USE-BUILDKIT Variable

Currently both the Kaniko and Buildkit overlays are available. Note that Kaniko is used by default. To enable Buildkit, set the SCR-BUILDER-USE-BUILDKIT environment variable to true.

```sh
kubectl set env deployment sas-decisions-runtime-builder SCR-BUILDER-USE-BUILDKIT=1 -n <name-of-namespace>
```

**Note:** SAS plans to discontinue the use of Kaniko in the future.

## Additional Resources

- [SAS Viya platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
- [Persistent Volume Claims on Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
- [Configuring Publishing Destinations](http://documentation.sas.com/?cdcId=mdlmgrcdc&cdcVersion=default&docsetId=mdlmgrag&docsetTarget=n0x0rvwqs9lvpun16sfdqoff4tsk.htm) in the _SAS Model Manager: Administrator's Guide_
- [Set environment variable in a Kubernetes deployment](https://www.mankier.com/1/kubectl-set-env)
