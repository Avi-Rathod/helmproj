---
category: sasProgrammingEnvironment
tocprty: 12
---

# SAS Programming Environment Storage Tasks

## Overview

The SAS Viya platform requires the ability to have write access to certain locations in the
environment. An example of this is the SASWORK location, where data used at
runtime may be created or modified. The SAS Programming Environment
container image is set up by default to use an emptyDir volume for this
purpose.  Depending on workload, you may need to configure different
storage classes for these volumes.

A storage class in Kubernetes is defined by a StorageClass resource.  Examples
of StorageClasses can be found at [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/).

This README describes how to use example files to configure the required
storage classes.

## Installation

The following processes assign their runtime storage locations using the
process described above.

* SAS Compute server
* SAS/CONNECT server
* SAS Batch server

The default behavior assigns an emptyDir volume for use for runtime storage by
these server applications.

This processing takes place at the initialization of the server application;
therefore these changes take effect upon the next launch of a pod for the
server application.

The volume storage class for these applications can be modified by using the
transformers in the example file located at
`$deploy/sas-bases/examples/sas-programming-environment/storage`.

1. Copy the
`$deploy/sas-bases/examples/sas-programming-environment/storage/change-viya-volume-storage-class.yaml`
file to the site-config directory.

2. To change the StorageClass replace the {{ VOLUME-STORAGE-CLASS }} variable
in the copied file with a different volume storage class.
The example file provided looks like the following:

   ```yaml
   - op: add
     path: /template/spec/volumes/-
     value:
       name: viya
       {{ VOLUME-STORAGE-CLASS }}
   ```

   For example, assume that the storage location you want to use is an NFS volume.   That volume may be
   described in the following way:

   ```yaml
   nfs:
     server: myserver.mycompany.com
     path: /path/to/my/location
   ```

   To use this in the transformer, substitute in the volume definition in the
   {{ VOLUME-STORAGE-CLASS }} location.  The result would look like this:

   ```yaml
   - op: add
     path: /template/spec/volumes/-
     value:
       name: viya
       nfs:
         server: myserver.mycompany.com
         path: /path/to/my/location
   ```

   **Note:** The transformer defined here delete the previously defined *viya*
   volume specification in the associated podTemplates.   Any content that may
   exist in the current *viya* volume is not affected by this transformer.

3. After you edit the change-viya-volume-storage-class.yaml file, add it to
the transformers block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   **Note:** The reference to the `site-config/change-viya-volume-storage-class.yaml` overlay must come before the required transformers.yaml.

   Here is an example assuming the file has been saved to
   `$deploy/site-config`:

   ```yaml
   transformers:
   ...
     - site-config/change-viya-volume-storage-class.yaml
     - sas-bases/overlays/required/transformers.yaml
   ...
   ```

## Additional Resources

For more information about deployment and using example files, see the
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).