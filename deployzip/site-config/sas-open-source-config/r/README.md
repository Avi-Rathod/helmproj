---
category: openSourceConfiguration
tocprty: 4
---

# Configure R for the SAS Viya Platform

## Overview

The SAS Viya platform can use a customer-prepared environment consisting of an R installation and any required packages stored on a Kubernetes Persistent Volume.
This README describes how to make that volume available to your deployment.

## Prerequisites

The SAS Viya platform provides YAML files that the Kustomize tool uses to configure R. Before you use those files, you must perform the following tasks:

1. Make note of the attributes of the volume where R and the associated packages are to be deployed. For example, note the server and directory for NFS.
   For more information about various types of persistent volumes in Kubernetes, see [Additional Resources](#additional-resources).

2. Install R and any necessary packages on the volume.

3. In addition to the volume attributes, you must have the following information:

   * {{ R-MOUNTPATH }} - the install path used when R is built excluding top-level directory (for example, /nfs/r-mount).
   * {{ R-HOMEDIR }} - the top-level directory of the R installation on that volume (for example, R-3.6.2).
   * {{ SAS-EXTLANG-SETTINGS-XML-FILE }} - configuration file for enabling Python and R integration in CAS. This is only needed if using R with either CMP or the EXTLANG package.
   * {{ SAS-EXT-LLP-R-PATH }} - list of directories to look for when searching for run-time shared libraries (similar to LD_LIBRARY_PATH).

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-open-source-config/r` directory to the `$deploy/site-config/sas-open-source-config/r` directory. Create the target directory, if it does not already exist.

   **Note:** If the destination directory already exists, [verify that the overlay](#verify-overlay-for-r-volume) has been applied.
   If the output contains the `/nfs/r-mount` directory path, you do not need to take any further actions, unless you want to change the overlay parameters to use a different R environment.

2. The kustomization.yaml file defines all the necessary environment variables. Replace all tags, such as {{ R-HOMEDIR }}, with the values that you gathered in the [Prerequisites](#prerequisites) step. Then, set the following parameters, according to the SAS products that you will be using:

   * DM_RHOME is used by the Open Source Code node in SAS Visual Data Mining and Machine Learning.
   * SAS_EXTLANG_SETTINGS is used by applications that run Python and R code on Cloud Analytic Services (CAS). This includes PROC FCMP and the Time Series External Languages (EXTLANG) package. SAS_EXTLANG_SETTINGS should only be set in one example file; for example, if you set it in the Python example, you should not set it the R example. SAS_EXTLANG_SETTINGS should point to an XML file that is readable by all users. The path can be in the same volume that contains the R environment or in any other volume that is accessible to CAS. Refer to the documentation for the Time Series External Languages (EXTLANG) package for details about the expected XML schema.
   * SAS_EXT_LLP_R is used when the base distribution or packages for open source software require additional run-time libraries that are not part of the shipped container image.

3. Attach storage to your SAS Viya platform deployment. The r-transformer.yaml file uses PatchTransformers in kustomize to attach the volume containing your R installation to the SAS Viya platform.

   * Replace {{ VOLUME-ATTRIBUTES }} with the appropriate volume specification. For example, when using an NFS mount, the {{ VOLUME-ATTRIBUTES }} tag should be replaced with `nfs: {path: /vol/r-mount, server: myserver.sas.com}` where `myserver.sas.com` is the NFS server and `/vol/r-mount` is the NFS path that you recorded in the Prerequisites.
   * Replace {{ R-MOUNTPATH }} with the install path used when R is built, excluding top-level directory.

   The relevant code excerpt from r-transformer.yaml file before the change:

   ```yaml
   patch: |-
   # Add R Volume
     - op: add
       path: /spec/template/spec/volumes/-
       value: { name: r-volume, {{ VOLUME-ATTRIBUTES }} }
   # Add mount path for R
     - op: add
       path: /template/spec/containers/0/volumeMounts/-
       value:
         name: r-volume
         mountPath: {{ R-MOUNTPATH }}
       readOnly: true
   ```

   The relevant code excerpt from r-transformer.yaml file after the change:

   ```yaml
   patch: |-
   # Add R Volume
     - op: add
       path: /spec/template/spec/volumes/-
       value: { name: r-volume, nfs: {path: /vol/r, server: myserver.sas.com} }
   # Add mount path for R
     - op: add
       path: /template/spec/containers/0/volumeMounts/-
       value:
         name: r-volume
         mountPath: /nfs/r-mount
         readOnly: true
   ```

4. Also in the r-transformer.yaml file, there is a PatchTransformer called sas-r-sas-java-policy-allow-list.  This PatchTransformer sets paths to the R interpreter so that the SAS runtime
   allows execution of the R script.  Replace the {{ R-MOUNTPATH }} and {{ R-HOMEDIR }} tags with the appropriate values.  Here is an example:

   ```yaml
   apiVersion: builtin
   kind: PatchTransformer
   metadata:
     name: add-r-sas-java-policy-allow-list
   patch: |-
     - op: add
       path: /data/SAS_JAVA_POLICY_ALLOW_DM_RHOME
       value: /nfs/r/R-3.6.2/bin/Rscript
   target:
     kind: ConfigMap
     name: sas-programming-environment-java-policy-config
   ```

5. Make the following changes to the base kustomization.yaml file in the $deploy directory.

   * Add site-config/sas-open-source-config/r to the resources block.
   * Add site-config/sas-open-source-config/r/r-transformer.yaml to the transformers block.

   Here is an example:

   ```yaml
   resources:
   - site-config/sas-open-source-config/r

   transformers:
   - site-config/sas-open-source-config/r/r-transformer.yaml
   ```

6. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya Platform: Deployment Guide_.

    **Note:** This overlay can be applied during the initial deployment of the SAS Viya platform or after the deployment of the SAS Viya platform.

    * If you are applying the overlay during the initial deployment of the SAS Viya platform, complete all the tasks in the README files that you want to use, then run `kustomize build` to create and apply the manifests.
    * If the overlay is applied after the initial deployment of the SAS Viya platform, run `kustomize build` to create and apply the manifests.

## Verify Overlay for R Volume

1. Run the following command to verify whether the overlay has been applied:

   ```sh
   kubectl describe pod sas-cas-server-default-controller -n <name-of-namespace>
   ```

2. Verify that the output contains the following mount directory paths:

   ```yaml
   Mounts:
     /nfs/r-mount (r)
   ```

## Additional Resources

* [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
* [Persistent Volumes in Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
* [Volume Types in Kubernetes](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)
* [External Languages Access Control Configuration](http://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=default&docsetId=castsp&docsetTarget=castsp_extlang_sect002.htm&locale=en) in _SAS Viya Platform Programming Documentation_
