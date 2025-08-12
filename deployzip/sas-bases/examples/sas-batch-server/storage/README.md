---
category: sasProgrammingEnvironment
tocprty: 14
---

# SAS Batch Server Storage Task for Checkpoint/Restart

## Overview

A SAS Batch Server has the ability to restart a SAS job using
either SAS's data step checkpoint/restart capability or
SAS's label checkpoint/restart capability.
For the checkpoint/restart capability to work properly, the checkpoint
information must be stored on storage that persists across all compute
nodes in the deployment. When the Batch Server job is restarted, it will have
access to the checkpoint information no matter what compute node it is started on.

The checkpoint information is stored in SASWORK, which is allocated in
the volume named `viya`. Since a Batch Server is a SAS Viya platform server that
uses the SAS Programming Run-Time Environment, it is possible that the
`viya` volume may be set to ephemeral storage by the
`$deploy/sas-bases/examples/sas-programming-environment/storage/change-viya-volume-storage-class.yaml`
transformers. If that is the case, the Batch Server's `viya` volume would need
to be changed to persistent storage without changing any other server's
storage.

**Note:** For more information about changing the storage for SAS Viya platform servers that use the SAS Programming Run-Time Environment, see the README file at `$deploy/sas-bases/examples/sas-programming-environment/storage/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/sas_programming_environment_storage_tasks.htm` (for HTML format).

The transformers described in this README sets the storage class for the SAS Batch
Server's `viya` volume defined in the SAS Batch Server pod templates without
changing the storage of the other SAS Viya platform servers that use the SAS
Programming Run-Time Environment.

## Installation

The changes described by this README take place at the initialization of
the server application; therefore the changes take effect at the next
launch of a pod for the server application.

The volume storage class for these applications can be modified by using the
example file located at `$deploy/sas-bases/examples/sas-batch-server/storage`.

1. Copy the
`$deploy/sas-bases/examples/sas-batch-server/storage/change-batch-server-viya-volume-storage-class.yaml`
file to the site-config directory.

2. To change the storage class, replace the {{ VOLUME-STORAGE-CLASS }} variable
in the copied file with a different volume storage class.
The unedited example file contains a transformer that looks like this:

   ```yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: add-batch-viya-volume
    patch: |-
      - op: add
        path: /template/spec/volumes/-
        value:
          name: viya
          {{ VOLUME-STORAGE-CLASS }}
    target:
      kind: PodTemplate
      labelSelector: "launcher.sas.com/job-type=sas-batch-job"
   ```

   Assume that the storage location you want to use is an NFS volume.   That volume may be
   described in the following way:

   ```yaml
    nfs:
      server: myserver.mycompany.com
      path: /path/to/my/location
   ```

   To use this storage location in the transformer, substitute in the volume definition in the
   {{ VOLUME-STORAGE-CLASS }} location.  The result would look like this:

   ```yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: add-batch-viya-volume
    patch: |-
      - op: add
        path: /template/spec/volumes/-
        value:
          name: viya
          nfs:
            server: myserver.mycompany.com
            path: /path/to/my/location
    target:
      kind: PodTemplate
      labelSelector: launcher.sas.com/job-type=sas-batch-job
   ```

   **Note:** The first transformer defined in the example file deletes the previously defined `viya`
   volume specification in the associated podTemplates and the second transformer in the example file
   adds the `viya` volume you defined. Any content that may
   exist in the current `viya` volume is not affected by these transformers.

3. After you edit the change-batch-server-viya-volume-storage-class.yaml file, add it to the transformers block
   of the base kustomization.yaml file (`$deploy/kustomization.yaml`) before the required transformers.yaml.

   **Note:** If the `$deploy/sas-bases/examples/sas-programming-environment/storage/change-viya-volume-storage-class.yaml`
   transformers file is also being used in the base kustomization.yaml file,
   ensure the Batch Server transformers file is located **after** the entry for
   the `change-viya-volume-storage-class.yaml` patch.
   Otherwise the Batch Server patch will have no effect.

   Here is an example assuming the file has been saved to
   `$deploy/site-config`:

   ```yaml
   transformers:
   ...
   <...other transformers...>
   < site-config/change-viya-volume-storage-class.yaml if used>
   - site-config/change-batch-server-viya-volume-storage-class.yaml
   - sas-bases/overlays/required/transformers.yaml
   ...
   ```

## Additional Resources

For more information about deployment and using example files, see the
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).